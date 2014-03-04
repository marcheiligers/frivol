module Frivol
  # == Frivol::ClassMethods
  # These methods are available on the class level when Frivol is included in the class.
  module ClassMethods
    # Set the storage expiry time in seconds for the default bucket or the bucket passed.
    def storage_expires_in(time, bucket = nil)
      @frivol_storage_expiry ||= {}
      @frivol_storage_expiry[bucket.to_s] = time
    end

    # Get the storage expiry time in seconds for the default bucket or the bucket passed.
    def storage_expiry(bucket = nil)
      @frivol_storage_expiry ||= {}
      @frivol_storage_expiry.key?(bucket.to_s) ? @frivol_storage_expiry[bucket.to_s] : NEVER_EXPIRE
    end

    # Create a storage bucket.
    # Frivol creates store_#{bucket} and retrieve_#{bucket} methods automatically.
    # These methods work exactly like the default store and retrieve methods except that the bucket is
    # stored in it's own key in Redis and can have it's own expiry time.
    #
    # Counters are special in that they do not store a hash but only a single integer value and also
    # that the data in a counter is not cached for the lifespan of the object, but rather each call
    # hits Redis. This is intended to make counters thread safe (for example you may have multiple
    # workers working on a job and they can each increment a progress counter which would not work
    # with the default retrieve/store method that normal buckets use). For this to actually be thread safe
    # you need to pass the thread safe option to the config when you make the connection.
    #
    # In the case of a counter, the methods work slightly differently:
    # - store_#{bucket} only takes an integer value to store (no key)
    # - retrieve_#{bucket} only takes an integer default, and returns only the integer value
    # - there is an added increment_#{bucket} method which increments the counter by 1
    # - as well as increment_#{bucket}_by(value) method which increments the counter by the value
    # - and similar decrement_#{bucket} and decrement_#{bucket}_by(value) methods
    #
    # Options are
    # - <tt>:expires_in</tt> which sets the expiry time for a bucket;
    # - <tt>:counter</tt> to create a special counter storage bucket;
    # - <tt>:condition</tt> that must be satisfied before an action is taken on a bucket;
    # - <tt>:else</tt>, which is an action that is performed if <tt>:condition</tt> is not satisfied
    def storage_bucket(bucket, options = {})
      time = options[:expires_in]
      storage_expires_in(time, bucket) if !time.nil?

      is_counter    = options[:counter]
      seed_callback = options[:seed]


      condition_block = Functor.new(options[:condition], true).compile
      else_block      = Functor.new(options[:else]).compile

      define_method :condition_evaluation do |*args, &block|
        if instance_exec(*args, &condition_block)
          block.call
        else
          instance_exec(*args, &else_block)
        end
      end

      self.class_eval do
        if is_counter
          define_method "store_#{bucket}" do |value|
            condition_evaluation("store_#{bucket}", value) do
              Frivol::Helpers.store_counter(self, bucket, value)
            end
          end

          define_method "retrieve_#{bucket}" do |default|
            return_value = default
            condition_evaluation("store_#{bucket}", default) do
              return_value = Frivol::Helpers.retrieve_counter(self, bucket, default)
            end
            return_value
          end

          define_method "increment_#{bucket}" do
            condition_evaluation("increment_#{bucket}") do
              Frivol::Helpers.increment_counter(self, bucket, seed_callback)
            end
          end

          define_method "increment_#{bucket}_by" do |amount|
            condition_evaluation("increment_#{bucket}_by", amount) do
              Frivol::Helpers.increment_counter_by(self, bucket, amount, seed_callback)
            end
          end

          define_method "decrement_#{bucket}" do
            Frivol::Helpers.decrement_counter(self, bucket, seed_callback)
          end

          define_method "decrement_#{bucket}_by" do |amount|
            Frivol::Helpers.decrement_counter_by(self, bucket, amount, seed_callback)
          end
        else
          define_method "store_#{bucket}" do |keys_and_values|
            condition_evaluation("store_#{bucket}", keys_and_values) do
              hash = Frivol::Helpers.retrieve_hash(self, bucket)
              keys_and_values.each do |key, value|
                hash[key.to_s] = value
              end
              Frivol::Helpers.store_hash(self, hash, bucket)
            end
          end

          define_method "retrieve_#{bucket}" do |keys_and_defaults|
            hash = {}
            condition_evaluation("store_#{bucket}", keys_and_defaults) do
              hash = Frivol::Helpers.retrieve_hash(self, bucket)
            end

            result = keys_and_defaults.map do |key, default|
              hash[key.to_s] || (default.is_a?(Symbol) && respond_to?(default) && send(default)) || default
            end
            return result.first if result.size == 1
            result
          end
        end

        define_method "delete_#{bucket}" do
          condition_evaluation("delete_#{bucket}") do
            Frivol::Helpers.delete_hash(self, bucket)
          end
        end

        define_method "clear_#{bucket}" do
          condition_evaluation("clear_#{bucket}") do
            Frivol::Helpers.clear_hash(self, bucket)
          end
        end
      end

      # Use Frivol to cache results for a method (similar to memoize).
      # Options are :bucket which sets the bucket name for the storage,
      # :expires_in which sets the expiry time for a bucket,
      # and :counter to create a special counter storage bucket.
      #
      # If not :counter the key is the method_name.
      #
      # If you supply :expires_in you must also supply a :bucket otherwise
      # it is ignored (and the default class expires_in is used if supplied).
      #
      # If :counter and no :bucket is provided the :bucket is set to the
      # :bucket is set to the method_name (and so the :expires_in will be used).
      def frivolize(method_name, options = {})
        bucket        = options[:bucket]
        time          = options[:expires_in]
        is_counter    = options[:counter]
        seed_callback = options[:seed]

        bucket = method_name if bucket.nil? && is_counter
        frivolized_method_name = "frivolized_#{method_name}"

        self.class_eval do
          alias_method frivolized_method_name, method_name
          unless bucket.nil?
            storage_bucket(bucket, {
              :expires_in => time,
              :counter    => is_counter,
              :seed       => seed_callback })
          end

          if is_counter
            define_method method_name do
              value = send "retrieve_#{bucket}", -2147483647 # A rediculously small number that is unlikely to be used: -2**31 + 1
              if value == -2147483647
                value = send frivolized_method_name
                send "store_#{bucket}", value
              end
              value
            end
          elsif !bucket.nil?
            define_method method_name do
              value = send "retrieve_#{bucket}", { method_name => false }
              if !value
                value = send frivolized_method_name
                send "store_#{bucket}", { method_name => value }
              end
              value
            end
          else
            define_method method_name do
              value = retrieve method_name => false
              if !value
                value = send frivolized_method_name
                store method_name.to_sym => value
              end
              value
            end
          end
        end
      end
    end
  end
end
