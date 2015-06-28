require "redis"

module Frivol
  module Backend
    # == Configuration
    # This is a connection to a single Redis server and the simplest backend.
    #   REDIS_CONFIG = {
    #     :host => "localhost",
    #     :port => 6379
    #   }
    #   Frivol::Config.backend = Frivol::Backend::Redis.new(REDIS_CONFIG)
    class Redis
      # :nodoc:
      def initialize(config)
        @config = config
      end

      # Hashes
      def get(key, expiry = Frivol::NEVER_EXPIRE)
        connection.get(key)
      end
      alias_method :getc, :get # Counter method alias

      def set(key, val, expiry = Frivol::NEVER_EXPIRE)
        set_with_expiry(key, val, expiry)
      end
      alias_method :setc, :set # Counter method alias

      def del(key)
        connection.del(key)
      end
      alias_method :delc, :del # Counter method alias

      def exists(key)
        connection.exists(key)
      end
      alias_method :existsc, :exists # Counter method alias

      # Counters
      def incr(key, expiry = Frivol::NEVER_EXPIRE)
        set_with_expiry(key, 1, expiry, :incrby)
      end

      def decr(key, expiry = Frivol::NEVER_EXPIRE)
        set_with_expiry(key, 1, expiry, :decrby)
      end

      def incrby(key, amt, expiry = Frivol::NEVER_EXPIRE)
        set_with_expiry(key, amt, expiry, :incrby)
      end

      def decrby(key, amt, expiry = Frivol::NEVER_EXPIRE)
        set_with_expiry(key, amt, expiry, :decrby)
      end

      # Expiry/TTL
      def expire(key, ttl)
        connection.expire(key, ttl)
      end

      def ttl(key)
        time = connection.ttl(key)
        time < 0 ? nil : time
      end

      # Connection
      def flushdb
        connection.flushdb
      end

      def connection
        Thread.current[thread_key] ||= ::Redis.new(@config)
      end

    private
      def thread_key
        @thread_key ||= @config.hash.to_s.to_sym
      end

      def set_with_expiry(key, val, expiry, method = :set)
        if expiry == Frivol::NEVER_EXPIRE
          connection.send(method, key, val)
        else
          result = connection.multi do |redis|
            redis.send(method, key, val)
            redis.expire(key, expiry)
          end
          result[0]
        end
      end
    end
  end
end