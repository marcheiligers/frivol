module Frivol
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
      @@redis_config = config
      Thread.current[:frivol_redis] = nil
    end

    # Returns the configured Redis instance
    def self.redis
      Thread.current[:frivol_redis] ||= Redis.new(@@redis_config)
    end

    def self.allow_json_create
      @@allow_json_create ||= []
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
end
