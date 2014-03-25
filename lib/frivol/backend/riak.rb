require "riak"

module Frivol
  module Backend
    class Riak
      def initialize(config)
        @config = config
      end

      # Hashes
      def get(key, expiry = Frivol::NEVER_EXPIRE)
        obj = objects_bucket.get_or_new(key)
        expires_in = ttl(key)
        if expires_in.nil? || expires_in > 0
          obj.raw_data
        else
          obj.delete
          nil
        end
      end

      def set(key, val, expiry = Frivol::NEVER_EXPIRE)
        obj = objects_bucket.get_or_new(key)
        obj.raw_data = val
        obj.content_type = 'text/plain'
        obj.store
        expire(key, expiry) unless expiry == Frivol::NEVER_EXPIRE
      end

      def del(key)
        objects_bucket.delete(key)
      end

      def exists(key)
        exists = objects_bucket.exist?(key)
        if exists
          expires_in = ttl(key)
          if expires_in.nil? || expires_in > 0
            true
          else
            objects_bucket.delete(key)
            false
          end
        end
      end

      # Counters
      def getc(key, expiry = Frivol::NEVER_EXPIRE)
        cnt = counters_bucket.counter(key) if existsc(key)
        expires_in = ttl(key)
        if expires_in.nil? || expires_in > 0
          cnt ? cnt.value : nil
        else
          delc(key)
          nil
        end
      end

      def setc(key, val, expiry = Frivol::NEVER_EXPIRE)
        delc(key)
        cnt = counters_bucket.counter(key)
        cnt.increment(val)
        expire(key, expiry) unless expiry == Frivol::NEVER_EXPIRE
      end

      def delc(key)
        counters_bucket.delete(key)
      end

      def existsc(key)
        exists = counters_bucket.exist?(key)
        if exists
          expires_in = ttl(key)
          if expires_in.nil? || expires_in > 0
            true
          else
            counters_bucket.delete(key)
            false
          end
        end
      end

      def incr(key, expiry = Frivol::NEVER_EXPIRE)
        cnt = counters_bucket.counter(key)
        cnt.increment
        expire(key, expiry) unless expiry == Frivol::NEVER_EXPIRE
        cnt.value
      end

      def decr(key, expiry = Frivol::NEVER_EXPIRE)
        cnt = counters_bucket.counter(key)
        cnt.decrement
        expire(key, expiry) unless expiry == Frivol::NEVER_EXPIRE
        cnt.value
      end

      def incrby(key, amt, expiry = Frivol::NEVER_EXPIRE)
        cnt = counters_bucket.counter(key)
        cnt.increment(amt)
        expire(key, expiry) unless expiry == Frivol::NEVER_EXPIRE
        cnt.value
      end

      def decrby(key, amt, expiry = Frivol::NEVER_EXPIRE)
        cnt = counters_bucket.counter(key)
        cnt.decrement(amt)
        expire(key, expiry) unless expiry == Frivol::NEVER_EXPIRE
        cnt.value
      end

      # Expiry/TTL
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

      # Connection
      def flushdb
        objects_bucket.keys.each { |k| objects_bucket.delete(k) }
        counters_bucket.keys.each { |k| counters_bucket.delete(k) }
        expires_bucket.keys.each { |k| expires_bucket.delete(k) }
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