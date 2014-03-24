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

      def del(key)
        connection.del(key)
      end

      def exists(key)
        connection.exists(key)
      end

      # Counters
      def getc(key)
        connection.get(key)
      end

      def setc(key, val, expiry = Frivol::NEVER_EXPIRE)
        if expiry == Frivol::NEVER_EXPIRE
          connection.set(key, val)
        else
          connection.multi do |redis|
            redis.set(key, val)
            redis.expire(key, expiry)
          end
        end
      end

      def delc(key)
        connection.del(key)
      end

      def existsc(key)
        connection.exists(key)
      end

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