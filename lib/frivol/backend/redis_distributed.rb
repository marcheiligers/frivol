require "redis"
require "redis/distributed"
require File.join(File.dirname(__FILE__), "redis")

module Frivol
  module Backend
    class RedisDistributed < Frivol::Backend::Redis
      def set(key, val, expiry = Frivol::NEVER_EXPIRE)
        if expiry == Frivol::NEVER_EXPIRE
          connection.set(key, val)
        else
          connection.node_for(key).multi do |redis|
            redis.set(key, val)
            redis.expire(key, expiry)
          end
        end
      end
      alias_method :setc, :set # Counter method alias

      def connection
        Thread.current[thread_key] ||= ::Redis::Distributed.new(@config)
      end

    private
      def set_with_expiry(key, val, expiry, method = :set)
        if expiry == Frivol::NEVER_EXPIRE
          connection.send(method, key, val)
        else
          connection.node_for(key).multi do |redis|
            redis.send(method, key, val)
            redis.expire(key, expiry)
          end
        end
      end
    end
  end
end