require "redis"
require "redis/distributed"
require File.join(File.dirname(__FILE__), "redis")

module Frivol
  module Backend
    # == Configuration
    # While it's not well known or documented, the Redis gem includes a sharding implementation in
    # Redis::Distributed[http://www.rubydoc.info/gems/redis/3.2.1/Redis/Distributed]. This backend
    # makes that available for Frivol.
    #   REDIS_CONFIG = [{
    #     :host => "localhost",
    #     :port => 6379
    #   }, {
    #     :host => "localhost",
    #     :port => 6380
    #   }]
    #   Frivol::Config.backend = Frivol::Backend::RedisDistributed.new(REDIS_CONFIG)
    class RedisDistributed < Frivol::Backend::Redis
      # :nodoc:
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
          results = connection.node_for(key).multi do |redis|
            redis.send(method, key, val)
            redis.expire(key, expiry)
          end
          results[0]
        end
      end
    end
  end
end