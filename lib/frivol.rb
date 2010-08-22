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
# <tt>delete_storage</tt>, as the name suggests will immediately delete the storage.
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
#     def storage_key
#       "frivol-test-#{key}" # override the storage key because we don't respond_to? id
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
  # Store a hash of keys and values.
  #
  # The hash need not be the complete hash of all things stored, just those you want to change.
  # For example, you may call <tt>store :value1 => 1</tt> and then later call <tt>store :value2 => 2</tt>
  # and Frivol will now have stored <tt>{ :value1 => 1, :value => 2 }</tt>. How Frivol stores or retrieves data
  # is intended to be hidden and while it is true that it currently uses a <tt>Hash#to_json</tt> you should not
  # rely on this.
  def store(keys_and_values)
    Frivol::Helpers.retrieve_hash self
    keys_and_values.each do |key, value|
      @frivol_hash[key.to_s] = value
    end
    Frivol::Helpers.store_hash self
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
    Frivol::Helpers.retrieve_hash self
    result = keys_and_defaults.map do |key, default|
      @frivol_hash[key.to_s] || (default.is_a?(Symbol) && respond_to?(default) && send(default)) || default
    end
    return result.first if result.size == 1
    result
  end
  
  # Deletes the stored values.
  def delete_storage
    Frivol::Helpers.delete_hash self
  end
  
  # Expire the stored data in +time+ seconds.
  def expire_storage(time)
    return if time.nil?
    Frivol::Config.redis.expire storage_key, time
  end
  
  # The base key used for storage in Redis. 
  #
  # This method has been implemented for use with ActiveRecord and uses <tt>"#{self.class.name}-#{id}"</tt>
  # If you are not using ActiveRecord, or using classes that don't respond to id, you should override
  # this method in your class.
  def storage_key
    @frivol_key ||= "#{self.class.name}-#{id}"
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
    
    def self.delete_hash(instance)
      key = instance.send(:storage_key)
      Frivol::Config.redis.del key
      instance.instance_variable_set :@frivol_hash, {}
    end
  end
  
  # == Frivol::ClassMethods
  # These methods are available on the class level when Frivol is included in the class.
  module ClassMethods
    # Set the storage expiry time in seconds.
    def storage_expires_in(time)
      @frivol_storage_expiry = time
    end
    
    # Get the storage expiry time in seconds.
    def storage_expiry
      @frivol_storage_expiry
    end
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