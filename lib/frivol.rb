require "redis"

# == Frivol
module Frivol
  require "frivol/config"
  require "frivol/functor"
  require "frivol/helpers"
  require "frivol/class_methods"
  require "frivol/backend/redis"

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
    Frivol::Config.backend.expire storage_key(bucket), time
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

  def self.included(host) #:nodoc:
    host.extend(ClassMethods)
  end
end
