require "json"
require "redis"

module Frivol
  def store(keys_and_values)
    Frivol::Helpers.retrieve_hash self
    keys_and_values.each do |key, value|
      @frivol_hash[key.to_s] = value
    end
    Frivol::Helpers.store_hash self
  end
  
  def retrieve(keys_and_defaults)
    Frivol::Helpers.retrieve_hash self
    result = keys_and_defaults.map do |key, default|
      @frivol_hash[key.to_s] || (respond_to?(default) && send(default)) || default
    end
    return result.first if result.size == 1
    result
  end
  
  def expire_storage(time)
    return if time.nil?
    Frivol::Config.redis.expire storage_key, time
  end
  
  def storage_key
    @frivol_key ||= "#{self.class.name}-#{id}"
  end
  
  module Config
    def self.redis_config=(config)
      @@redis = Redis.new(config)
    end
    
    def self.redis
      @@redis
    end
    
    def self.include_in(host_class, storage_expires_in = nil)
      host_class.send(:include, Frivol)
      host_class.storage_expires_in storage_expires_in if storage_expires_in
    end
  end
  
  module Helpers
    def self.store_hash(instance)
      hash = instance.instance_variable_get(:@frivol_hash)
      is_new = instance.instance_variable_get(:@frivol_is_new)
      key = instance.send(:storage_key)
      Frivol::Config.redis[key] = hash.to_json
      if is_new
        instance.expire_storage instance.class.storage_expiry
        instance.instance_variable_set :@frivol_is_new, false
      end
    end

    def self.retrieve_hash(instance)
      return instance.instance_variable_get(:@frivol_hash) if instance.instance_variable_defined? :@frivol_hash
      key = instance.send(:storage_key)
      json = Frivol::Config.redis[key]
      instance.instance_variable_set :@frivol_is_new, json.nil?
      hash = json.nil? ? {} : JSON.parse(json)
      instance.instance_variable_set :@frivol_hash, hash
      hash
    end
  end
  
  module ClassMethods
    def storage_expires_in(time)
      @frivol_storage_expiry = time
    end
    
    def storage_expiry
      @frivol_storage_expiry
    end
  end
  
  def self.included(host)
    host.extend(ClassMethods)
  end
end

class Time
  def to_json(*a)
    {
      'json_class'   => self.class.name,
      'data'         => self.to_s
    }.to_json(*a)
  end

  def self.json_create(o)
    Time.parse(*o['data'])
  end
end