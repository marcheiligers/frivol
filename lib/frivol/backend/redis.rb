require "redis"

module Frivol
  module Backend
    class Redis
      def initialize(config)
        @config = config
      end

      def get(key)
        connection.get(key)
      end

      def set(key, val)
        connection.set(key, val)
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

      def del(key)
        connection.del(key)
      end

      def expire(key, ttl)
        connection.expire(key, ttl)
      end

      def exists(key)
        connection.exists(key)
      end

      def ttl(key)
        connection.ttl(key)
      end

      def multi
        connection.multi do |redis|
          yield redis
        end
      end

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