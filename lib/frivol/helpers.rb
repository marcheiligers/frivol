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

      key = instance.send(:storage_key, bucket)
      time = instance.class.storage_expiry(bucket)
      Frivol::Config.backend.set(key, dump_json(hash), is_new ? time : nil)

      self.set_data_and_is_new instance, data, is_new
    end

    def self.retrieve_hash(instance, bucket = nil)
      data, is_new = get_data_and_is_new instance
      return data[bucket.to_s] if data.key?(bucket.to_s)
      key = instance.send(:storage_key, bucket)
      time = instance.class.storage_expiry(bucket)
      json = Frivol::Config.backend.get(key, time)

      is_new[bucket.to_s] = json.nil?

      hash = json.nil? ? {} : load_json(json)
      data[bucket.to_s] = hash

      self.set_data_and_is_new instance, data, is_new
      hash
    end

    def self.delete_hash(instance, bucket = nil)
      key = instance.send(:storage_key, bucket)
      Frivol::Config.backend.del key
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
      exists = Frivol::Config.backend.existsc(key)
      time = instance.class.storage_expiry(counter)
      Frivol::Config.backend.setc(key, value, exists ? nil : time)
    end

    def self.retrieve_counter(instance, counter, default)
      key = instance.send(:storage_key, counter)
      time = instance.class.storage_expiry(counter)
      (Frivol::Config.backend.getc(key, time) || default).to_i
    end

    def self.increment_counter(instance, counter, seed_callback=nil)
      key = instance.send(:storage_key, counter)
      store_counter_seed_value(key, instance, counter, seed_callback)
      exists = Frivol::Config.backend.existsc(key)
      time = instance.class.storage_expiry(counter)
      Frivol::Config.backend.incr(key, exists ? nil : time)
    end

    def self.increment_counter_by(instance, counter, amount, seed_callback=nil)
      key = instance.send(:storage_key, counter)
      store_counter_seed_value(key, instance, counter, seed_callback)
      exists = Frivol::Config.backend.existsc(key)
      time = instance.class.storage_expiry(counter)
      Frivol::Config.backend.incrby(key, amount, exists ? nil : time)
    end

    def self.decrement_counter(instance, counter, seed_callback=nil)
      key = instance.send(:storage_key, counter)
      store_counter_seed_value(key, instance, counter, seed_callback)
      exists = Frivol::Config.backend.existsc(key)
      time = instance.class.storage_expiry(counter)
      Frivol::Config.backend.decr(key, exists ? nil : time)
    end

    def self.decrement_counter_by(instance, counter, amount, seed_callback=nil)
      key = instance.send(:storage_key, counter)
      store_counter_seed_value(key, instance, counter, seed_callback)
      exists = Frivol::Config.backend.existsc(key)
      time = instance.class.storage_expiry(counter)
      Frivol::Config.backend.decrby(key, amount, exists ? nil : time)
    end

    def self.delete_counter(instance, counter = nil)
      key = instance.send(:storage_key, counter)
      Frivol::Config.backend.delc key
      clear_hash(instance, counter)
    end

    def self.store_counter_seed_value(key, instance, counter, seed_callback)
      unless Frivol::Config.backend.existsc(key) || seed_callback.nil?
        store_counter( instance, counter, seed_callback.call(instance))
      end
    end
    private_class_method :store_counter_seed_value
  end
end
