require "json"
require "redis"

module Frivol
  def store(keys_and_values)
    retrieve_hash
    keys_and_values.each do |key, value|
      @frivol_hash[key.to_s] = value
    end
    
    Frivol::Config.redis[storage_key] = @frivol_hash.to_json
  end
  
  def retrieve(keys_and_defaults)
    retrieve_hash
    result = keys_and_defaults.map do |key, default|
      @frivol_hash[key.to_s] || (respond_to?(default) && send(default)) || default
    end
    return result.first if result.size == 1
    result
  end
  
  def retrieve_hash
    @frivol_hash if defined? @frivol_hash
    json = Frivol::Config.redis[storage_key]
    @frivol_hash = json.nil? ? {} : JSON.parse(json)
  end
  
  def expire_storage(time)
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