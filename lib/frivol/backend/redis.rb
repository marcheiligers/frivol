require "redis"

module Frivol
  module Backend
    class Redis
      def initialize(config)
        @config = config
      end

      # Hashes
      def get(key)
        connection.get(key)
      end
      alias_method :getc, :get # Counter method alias

      def set(key, val, expiry = Frivol::NEVER_EXPIRE)
        if expiry == Frivol::NEVER_EXPIRE
          connection.set(key, val)
        else
          connection.multi do |redis|
            redis.set(key, val)
            redis.expire(key, expiry)
          end
        end
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
      def incr(key)
        connection.incr(key)
      end

      def decr(key)
        connection.decr(key)
      end

      def incrby(key, amt)
        connection.incrby(key, amt)
      end

      def decrby(key, amt)
        connection.decrby(key, amt)
      end

      # Expiry/TTL
      def expire(key, ttl)
        connection.expire(key, ttl)
      end

      def ttl(key)
        connection.ttl(key)
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
    end
  end
end