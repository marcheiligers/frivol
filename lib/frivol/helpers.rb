module Frivol
  module Helpers #:nodoc:
    require 'multi_json'

    def self.dump_json(hash)
      MultiJson.dump(hash)
    end

    def self.load_json(json)
      hash = MultiJson.load(json)
      return hash if Frivol::Config.allow_json_create.empty?
      hash.each do |k,v|
        if v.is_a?(Hash) && v['json_class']
          klass = constantize(v['json_class'])
          hash[k] = klass.send(:json_create, v) if Frivol::Config.allow_json_create.include?(klass)
        end
      end
    end

    def self.constantize(const)
      unless /\A(?:::)?([A-Z]\w*(?:::[A-Z]\w*)*)\z/ =~ const
        raise NameError, "#{const.inspect} is not a valid constant name!"
      end
      Object.module_eval("::#{$1}", __FILE__, __LINE__)
    end


    def self.store_hash(instance, hash, bucket = nil)
      data, is_new = get_data_and_is_new instance
      data[bucket.to_s] = hash

      store_value instance, is_new[bucket.to_s], dump_json(hash), bucket

      self.set_data_and_is_new instance, data, is_new
    end

    def self.store_value(instance, is_new, value, bucket = nil)
      key = instance.send(:storage_key, bucket)
      time = instance.class.storage_expiry(bucket)
      if time == Frivol::NEVER_EXPIRE
        Frivol::Config.redis[key] = value
      else
        Frivol::Config.redis.multi do |redis|
          # TODO: write test for the to_i bug fix
          time = redis.ttl(key).to_i unless is_new
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

      hash = json.nil? ? {} : load_json(json)
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
end
