require "json"
require "redis"

module Frivol
  def store(keys_and_values)
    retrieve_hash
    keys_and_values.each do |key, value|
      @frivol_hash[key.to_s] = value
    end
    store_hash
  end
  
  def retrieve(keys_and_defaults)
    retrieve_hash
    result = keys_and_defaults.map do |key, default|
      @frivol_hash[key.to_s] || (respond_to?(default) && send(default)) || default
    end
    return result.first if result.size == 1
    result
  end
  
  def store_hash(hash = nil)
    @frivol_hash = hash if hash
    Frivol::Config.redis[storage_key] = @frivol_hash.to_json
    expire_storage self.class.storage_expiry if @frivol_is_new
    @frivol_is_new = false
  end
  
  def retrieve_hash
    return @frivol_hash if defined? @frivol_hash
    json = Frivol::Config.redis[storage_key]
    @frivol_is_new = json.nil?
    @frivol_hash = @frivol_is_new ? {} : JSON.parse(json)
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