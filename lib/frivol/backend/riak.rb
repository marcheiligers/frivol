require "riak"

module Frivol
  module Backend
    class Riak
      def initialize(config)
        @config = config
      end

      def get(key)
        obj = objects_bucket.get_or_new(key)
        expires_in = ttl(key)
        if expires_in.nil? || expires_in > 0
          obj.raw_data
        else
          obj.delete
          nil
        end
      end

      def set(key, val)
        obj = objects_bucket.get_or_new(key)
        obj.raw_data = val
        obj.content_type = 'text/plain'
        obj.store
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
        objects_bucket.get_or_new(key).delete
      end

      def exists(key)
        objects_bucket.exist?(key) || counters_bucket.exist?(key)
      end

      def expire(key, ttl)
        obj = expires_bucket.get_or_new(key)
        obj.raw_data = (Time.now.to_i + ttl).to_s
        obj.content_type = 'text/plain'
        obj.store
      end

      def ttl(key)
        obj = expires_bucket.get_or_new(key)
        expiry = obj.raw_data.to_i
        if expiry == 0
          nil
        else
          expiry - Time.now.to_i
        end
      end

      def multi
        yield self
      end

      def flushdb
        objects_bucket.keys { |k| del(k) }
        counters_bucket.keys { |k| del(k) }
        expires_bucket.keys { |k| del(k) }
        sleep 0.2 # Give Riak a little time to reach consistency
      end

      def connection
        Thread.current[thread_key] ||= begin
          @objects_bucket = nil
          @counters_bucket = nil
          @expires_bucket = nil
          ::Riak::Client.new(@config)
        end
      end

    private
      def objects_bucket
        @objects_bucket ||= begin
          bkt = connection.bucket("frivol_objects")
          bkt.props = { :last_write_wins => true }
          bkt
        end
      end

      def counters_bucket
        @counters_bucket ||= begin
          bkt = connection.bucket("frivol_counters")
          bkt.allow_mult = true
          bkt
        end
      end

      def expires_bucket
        @expires_bucket ||= begin
          bkt = connection.bucket("frivol_expires")
          bkt.props = { :last_write_wins => true }
          bkt
        end
      end

      def thread_key
        @thread_key ||= @config.hash.to_s.to_sym
      end
    end
  end
end