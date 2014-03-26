module Frivol
  module Backend
    class Multi
      def initialize(backends)
        @primary_backend = backends.shift
        @other_backends = backends
      end

      # Hashes
      def get(key, expiry = Frivol::NEVER_EXPIRE)
        val = @primary_backend.get(key)
        val = migrate(key, expiry) if val.nil?
        val
      end

      def set(key, val, expiry = Frivol::NEVER_EXPIRE)
        @other_backends.each { |be| be.del(key) }
        @primary_backend.set(key, val, expiry)
      end

      def del(key)
        @primary_backend.del(key)
        @other_backends.each { |be| be.del(key) }
      end

      def exists(key)
        @primary_backend.exists(key) ||
          @other_backends.detect { |be| be.exists(key) }
      end

      # Counters
      def getc(key, expiry = Frivol::NEVER_EXPIRE)
        val = @primary_backend.getc(key)
        val = migratec(key, :getc, 0, expiry) if val.nil?
        val
      end

      def setc(key, val, expiry = Frivol::NEVER_EXPIRE)
        @other_backends.each { |be| be.delc(key) }
        @primary_backend.setc(key, val, expiry)
      end

      def delc(key)
        @primary_backend.delc(key)
        @other_backends.each { |be| be.delc(key) }
      end

      def existsc(key)
        @primary_backend.existsc(key) ||
          @other_backends.detect { |be| be.existsc(key) }
      end

      def incr(key, expiry = Frivol::NEVER_EXPIRE)
        if @primary_backend.existsc(key)
          @primary_backend.incr(key)
        else
          migratec(key, :incrby, 1, expiry)
        end
      end

      def decr(key, expiry = Frivol::NEVER_EXPIRE)
        if @primary_backend.existsc(key)
          @primary_backend.decr(key)
        else
          migratec(key, :decrby, 1, expiry)
        end
      end

      def incrby(key, amt, expiry = Frivol::NEVER_EXPIRE)
        if @primary_backend.existsc(key)
          @primary_backend.incrby(key, amt)
        else
          migratec(key, :incrby, amt, expiry)
        end
      end

      def decrby(key, amt, expiry = Frivol::NEVER_EXPIRE)
        if @primary_backend.existsc(key)
          @primary_backend.decrby(key, amt)
        else
          migratec(key, :decrby, amt, expiry)
        end
      end

      # Expiry/TTL
      def expire(key, ttl)
        @primary_backend.expire(key, ttl)
      end

      def ttl(key)
        expiry = @primary_backend.ttl(key)
        if expiry.nil?
          @other_backends.each do |be|
            expiry = be.ttl(key)
            return expiry unless expiry.nil?
          end
          nil
        else
          expiry
        end
      end

      # Connection
      def flushdb
        @primary_backend.flushdb
        @other_backends.each { |be| be.flushdb }
      end

      def connection
        @primary_backend.connection
      end

      # Migration
      def migrate(key, expiry = Frivol::NEVER_EXPIRE)
        backend = @other_backends.detect { |be| be.exists(key) }
        if backend
          val = backend.get(key)
          ttl = backend.ttl(key)
          @primary_backend.set(key, val, ttl)
          @other_backends.each { |be| be.del key }
          val
        end
      end

      def migratec(key, method = :incrby, amt = 0, expiry = Frivol::NEVER_EXPIRE)
        backend = @other_backends.detect { |be| be.existsc(key) }
        if backend
          val = backend.getc(key).to_i
          ttl = backend.ttl(key)
          @primary_backend.incrby(key, val) unless val.zero?
          val = @primary_backend.send(method, key, amt) unless amt.zero? || method == :getc
          @primary_backend.expire(key, ttl) if ttl
          @other_backends.each { |be| be.delc key }
          val
        elsif method != :getc
          @primary_backend.send(method, key, amt, expiry)
        else
          nil
        end
      end
    end
  end
end