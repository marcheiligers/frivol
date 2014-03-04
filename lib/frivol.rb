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
# Fine grained control of storing and retrieving values from buckets can be controlled using the :condition and
# :else options.
#
#   storage_bucket :my_bucket,
#                  :condition => Proc.new{ |object, frivol_method, *args| ... },
#                  :else       => :your_method
#
# For the above example, frivol execute the :condition proc and passes the instance of the current class, which
# method is being attempted (increment, increment_by, store, retrieve, etc.) and any arguments that may have been
# passed on to frivol.
#
# If the condition returns a truthy result, the frivol method is executed unimpeded, otherwise frivol moves on to
# :else. :else for the above example is a method on the instance, and that method must be able to handle the same
# arguments the :condition proc take:
#
#   def your_method(object, frivol_method, *args)
#     ...
#   end
#
# The :condition and :else options can be specified as a proc, symbol, true or false.
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
  require "frivol/config"
  require "frivol/functor"
  require "frivol/helpers"
  require "frivol/class_methods"

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

  def self.included(host) #:nodoc:
    host.extend(ClassMethods)
  end
end
