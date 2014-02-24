# = Frivol - Frivolously simple temporary storage backed by Redis
# A really simple Redis-backed temporary storage mechanism intended to be used with ActiveRecord,
# but will work with other ORM's or any classes really.
#
# I developed Frivol secifically for use in Mad Mimi (http://madmimi.com) to help with caching
# of data which requires fairly long running (multi-second) database queries, and also to aid
# with communication of status from background Resque jobs running on the workers to the front
# end web servers. Redis was chosen because we already had Resque, which is Redis-backed. Also,
# unlike memcached, Redis persists it's data to disk, meaning there is far less warmup required
# when a hot system is restarted. Frivol's design is such that it solves our problem, but I
# believe it is generic enough to be used in many Rails web projects and even in other types of
# projects altogether.
#
# == Usage
# Configure Frivol in your configuration, for example in an initializer or in environment.rb
#   REDIS_CONFIG = {
#     :host => "localhost",
#     :port => 6379
#   }
#   Frivol::Config.redis_config = REDIS_CONFIG
# Now include Frivol in whichever classes you'd like to make use of temporary storage. You can optionally
# call the <tt>storage_expires_in(time)</tt> class method to set a default expiry. In your methods you can
# now call the <tt>store(keys_and_values)</tt> and <tt>retrieve(keys_and_defaults)</tt> methods.
#
# Defaults in the +retrieve+ method can be symbols, in which case Frivol will check if the class <tt>respond_to?</tt>
# a method by that name to get the default.
#
# The <tt>expire_storage(time)</tt> method can be used to set the expiry time in seconds of the temporary storage.
# The default is not to expire the storage, in which case it will live for as long as Redis keeps it.
# <tt>delete_storage</tt>, as the name suggests will immediately delete the storage, while <tt>clear_storage</tt>
# will clear the cache that Frivol keeps and force the next <tt>retrieve</tt> to return to Redis for the data.
#
# Since version 0.1.5 Frivol can create different storage buckets. Note that this introduces a breaking change
# to the <tt>storage_key</tt> method if you have overriden it. It now takes a +bucket+ parameter.
#
# Buckets can have their own expiry time and there are special counter buckets which simply keep an integer count.
#
#   storage_bucket :my_bucket, :expires_in => 5.minutes
#   storage_bucket :my_counter, :counter => true
#
# Given the above, Frivol will create <tt>store_my_bucket</tt> and <tt>retrieve_my_bucket</tt> methods which work
# exactly like the standard +store+ and +retrieve+ methods. There will also be <tt>store_my_counter</tt>,
# <tt>retrieve_my_counter</tt> and <tt>increment_my_counter</tt> methods. The counter store and retrieve only
# take a integer (value and default, respectively) and the increment does not take a parameter. Since version 0.2.1
# there is also <tt>increment_my_counter_by</tt>, <tt>decrement_my_counter</tt> and <tt>decrement_my_counter_by<tt>.
#
# These methods are thread safe if you pass <tt>:thread_safe => true</tt> to the Redis configuration.
#
# Frivol uses the +storage_key+ method to create a base key for storage in Redis. The current implementation uses
# <tt>"#{self.class.name}-#{id}"</tt> so you'll want to override that method if you have classes that don't
# respond to id.
#
# Frivol also extends Time to allow it to be (de)serialized to JSON, which currently used to store
# data in Redis.
# == Example
#   class BigComplexCalcer
#     include Frivol
#     storage_expires_in 600 # temporary storage expires in 10 minutes.
#
#     def initialize(key)
#       @key = key
#     end
#
#     def storage_key(bucket = nil)
#       "frivol-test-#{key}" # override the storage key because we don't respond_to? :id, and don't care about buckets
#     end
#
#     def big_complex_calc
#       retrieve :complex => :do_big_complex_calc # do_big_complex_calc is the method to get the default from
#     end
#
#     def last_calc_done
#       last = retrieve :last => nil # default is nil
#       return "never" if last.nil?
#       return "#{Time.now - last} seconds ago"
#     end
#
#     def do_big_complex_calc
#       # Wee! Do some really hard work here...
#       # ...still working...
#       store :complex => result, :last => Time.now # ...and let's keep the result for at least 10 minutes, as well as the last time we did it
#     end
#   end
require "json"
require "redis"

# == Frivol
module Frivol
  # Defines a constant to indicate that storage should never expire
  NEVER_EXPIRE = nil

  # Store a hash of keys and values.
  #
  # The hash need not be the complete hash of all things stored, just those you want to change.
  # For example, you may call <tt>store :value1 => 1</tt> and then later call <tt>store :value2 => 2</tt>
  # and Frivol will now have stored <tt>{ :value1 => 1, :value => 2 }</tt>. How Frivol stores or retrieves data
  # is intended to be hidden and while it is true that it currently uses a <tt>Hash#to_json</tt> you should not
  # rely on this.
  def store(keys_and_values)
    hash = Frivol::Helpers.retrieve_hash(self)
    keys_and_values.each do |key, value|
      hash[key.to_s] = value
    end
    Frivol::Helpers.store_hash(self, hash)
  end

  # Retrieve stored values, or defaults.
  #
  # If you retrieve a single key just that value is returned. If you retrieve multiple keys an array of
  # values is returned. You might do:
  #   name = retrieve :name => "Marc Heiligers"
  #   first_name, last_name = retrieve :first_name => "Marc", :last_name => "Heiligers"
  #
  # If the default is a symbol, Frivol will attempt to get the default from a method named after that symbol.
  # If the class does not <tt>respond_to?</tt> a method by that name, the symbol will assumed to be the default.
  def retrieve(keys_and_defaults)
    hash = Frivol::Helpers.retrieve_hash(self)
    result = keys_and_defaults.map do |key, default|
      hash[key.to_s] || (default.is_a?(Symbol) && respond_to?(default) && send(default)) || default
    end
    return result.first if result.size == 1
    result
  end

  # Deletes the stored values (and clears the cache).
  def delete_storage
    Frivol::Helpers.delete_hash self
  end

  # Clears the cached values and forces the next retrieve to fetch from Redis.
  def clear_storage
    Frivol::Helpers.clear_hash self
  end

  # Expire the stored data in +time+ seconds.
  def expire_storage(time, bucket = nil)
    return if time.nil?
    Frivol::Config.redis.expire storage_key(bucket), time
  end

  # The base key used for storage in Redis.
  #
  # This method has been implemented for use with ActiveRecord and uses <tt>"#{self.class.name}-#{id}"</tt>
  # for the default bucket and <tt>"#{self.class.name}-#{id}-#{bucket}"</tt> for a named bucket.
  # If you are not using ActiveRecord, or using classes that don't respond to id, you should override
  # this method in your class.
  #
  # NOTE: This method has changed since version 0.1.4, and now has the bucket parameter (default: nil)
  def storage_key(bucket = nil)
    @frivol_key ||= "#{self.class.name}-#{id}"
    bucket.nil? ? @frivol_key : "#{@frivol_key}-#{bucket}"
  end

  # == Frivol::Config
  # Sets the Frivol configuration (currently only the Redis config), allows access to the configured Redis instance,
  # and has a helper method to include Frivol in a class with an optional storage expiry parameter
  module Config
    # Set the Redis configuration.
    #
    # Expects a hash such as
    #   REDIS_CONFIG = {
    #     :host => "localhost",
    #     :port => 6379
    #   }
    #   Frivol::Config.redis_config = REDIS_CONFIG
    def self.redis_config=(config)
      @@redis = Redis.new(config)
    end

    # Returns the configured Redis instance
    def self.redis
      @@redis
    end

    # A convenience method to include Frivol in a class, with an optional storage expiry parameter.
    #
    # For example, you might have the following in environment.rb:
    #   Frivol::Config.redis_config = REDIS_CONFIG
    #   Frivol::Config.include_in ActiveRecord::Base, 600
    # Which would include Frivol in ActiveRecord::Base and set the default storage expiry to 10 minutes
    def self.include_in(host_class, storage_expires_in = nil)
      host_class.send(:include, Frivol)
      host_class.storage_expires_in storage_expires_in if storage_expires_in
    end
  end

  module Helpers #:nodoc:
    def self.store_hash(instance, hash, bucket = nil)
      data, is_new = get_data_and_is_new instance
      data[bucket.to_s] = hash

      store_value instance, is_new[bucket.to_s], hash.to_json, bucket

      self.set_data_and_is_new instance, data, is_new
    end

    def self.store_value(instance, is_new, value, bucket = nil)
      key = instance.send(:storage_key, bucket)
      time = instance.class.storage_expiry(bucket)
      if time == Frivol::NEVER_EXPIRE
        Frivol::Config.redis[key] = value
      else
        # TODO: write test for the to_i bug fix
        time = Frivol::Config.redis.ttl(key).to_i unless is_new
        Frivol::Config.redis.multi do |redis|
          redis[key] = value
          redis.expire(key, time)
        end
      end
    end

    def self.retrieve_hash(instance, bucket = nil)
      data, is_new = get_data_and_is_new instance
      return data[bucket.to_s] if data.key?(bucket.to_s)
      key = instance.send(:storage_key, bucket)
      json = Frivol::Config.redis[key]

      is_new[bucket.to_s] = json.nil?

      hash = json.nil? ? {} : JSON.parse(json)
      data[bucket.to_s] = hash

      self.set_data_and_is_new instance, data, is_new
      hash
    end

    def self.delete_hash(instance, bucket = nil)
      key = instance.send(:storage_key, bucket)
      Frivol::Config.redis.del key
      clear_hash(instance, bucket)
    end

    def self.clear_hash(instance, bucket = nil)
      key = instance.send(:storage_key, bucket)
      data = instance.instance_variable_defined?(:@frivol_data) ? instance.instance_variable_get(:@frivol_data) : {}
      data.delete(bucket.to_s)
      instance.instance_variable_set :@frivol_data, data
    end

    def self.get_data_and_is_new(instance)
      data = instance.instance_variable_defined?(:@frivol_data) ? instance.instance_variable_get(:@frivol_data) : {}
      is_new = instance.instance_variable_defined?(:@frivol_is_new) ? instance.instance_variable_get(:@frivol_is_new) : {}
      [data, is_new]
    end

    def self.set_data_and_is_new(instance, data, is_new)
      instance.instance_variable_set :@frivol_data, data
      instance.instance_variable_set :@frivol_is_new, is_new
    end

    def self.store_counter(instance, counter, value)
      key = instance.send(:storage_key, counter)
      is_new = !Frivol::Config.redis.exists(key)
      store_value instance, is_new, value, counter
    end

    def self.retrieve_counter(instance, counter, default)
      key = instance.send(:storage_key, counter)
      (Frivol::Config.redis[key] || default).to_i
    end

    def self.increment_counter(instance, counter, seed_callback=nil)
      key = instance.send(:storage_key, counter)
      store_counter_seed_value(key, instance, counter, seed_callback)
      Frivol::Config.redis.incr(key)
    end

    def self.increment_counter_by(instance, counter, amount, seed_callback=nil)
      key = instance.send(:storage_key, counter)
      store_counter_seed_value(key, instance, counter, seed_callback)
      Frivol::Config.redis.incrby(key, amount)
    end

    def self.decrement_counter(instance, counter, seed_callback=nil)
      key = instance.send(:storage_key, counter)
      store_counter_seed_value(key, instance, counter, seed_callback)
      Frivol::Config.redis.decr(key)
    end

    def self.decrement_counter_by(instance, counter, amount, seed_callback=nil)
      key = instance.send(:storage_key, counter)
      store_counter_seed_value(key, instance, counter, seed_callback)
      Frivol::Config.redis.decrby(key, amount)
    end

    def self.store_counter_seed_value(key, instance, counter, seed_callback)
      unless Frivol::Config.redis.exists(key) || seed_callback.nil?
        store_counter( instance, counter, seed_callback.call(instance))
      end
    end
    private_class_method :store_counter_seed_value
  end

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
    # Options are :expires_in which sets the expiry time for a bucket,
    # and :counter to create a special counter storage bucket.
    def storage_bucket(bucket, options = {})
      time = options[:expires_in]
      storage_expires_in(time, bucket) if !time.nil?

      is_counter    = options[:counter]
      seed_callback = options[:seed]

      self.class_eval do
        if is_counter
          define_method "store_#{bucket}" do |value|
            Frivol::Helpers.store_counter(self, bucket, value)
          end

          define_method "retrieve_#{bucket}" do |default|
            Frivol::Helpers.retrieve_counter(self, bucket, default)
          end

          define_method "increment_#{bucket}" do
            Frivol::Helpers.increment_counter(self, bucket, seed_callback)
          end

          define_method "increment_#{bucket}_by" do |amount|
            Frivol::Helpers.increment_counter_by(self, bucket, amount, seed_callback)
          end

          define_method "decrement_#{bucket}" do
            Frivol::Helpers.decrement_counter(self, bucket, seed_callback)
          end

          define_method "decrement_#{bucket}_by" do |amount|
            Frivol::Helpers.decrement_counter_by(self, bucket, amount, seed_callback)
          end
        else
          define_method "store_#{bucket}" do |keys_and_values|
            hash = Frivol::Helpers.retrieve_hash(self, bucket)
            keys_and_values.each do |key, value|
              hash[key.to_s] = value
            end
            Frivol::Helpers.store_hash(self, hash, bucket)
          end

          define_method "retrieve_#{bucket}" do |keys_and_defaults|
            hash = Frivol::Helpers.retrieve_hash(self, bucket)
            result = keys_and_defaults.map do |key, default|
              hash[key.to_s] || (default.is_a?(Symbol) && respond_to?(default) && send(default)) || default
            end
            return result.first if result.size == 1
            result
          end
        end

        define_method "delete_#{bucket}" do
          Frivol::Helpers.delete_hash(self, bucket)
        end

        define_method "clear_#{bucket}" do
          Frivol::Helpers.clear_hash(self, bucket)
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

    # def storage_default(keys_and_defaults)
    #   @frivol_defaults ||= {}
    #   @frivol_defaults.merge keys_and_defaults
    # end
  end

  def self.included(host) #:nodoc:
    host.extend(ClassMethods)
  end
end

# == Time
# An extension to the Time class which allows Time instances to be serialized by <tt>#to_json</tt> and deserialized by <tt>JSON#parse</tt>.
class Time
  # Serialize to JSON
  def to_json(*a)
    {
      'json_class'   => self.class.name,
      'data'         => self.to_s
    }.to_json(*a)
  end

  # Deserialize from JSON
  def self.json_create(o)
    Time.parse(*o['data'])
  end
end

if defined?( ActiveSupport::TimeWithZone )
  class ActiveSupport::TimeWithZone
    # Serialize to JSON
    def to_json(*a)
      {
        'json_class'   => self.class.name,
        'data'         => self.to_s
      }.to_json(*a)
    end

    # Deserialize from JSON
    def self.json_create(o)
      Time.zone.parse(*o['data'])
    end
  end
end
