require "#{File.expand_path(File.dirname(__FILE__))}/helper.rb"

class TestMultiBackendExpiry < Test::Unit::TestCase
  if multi_test?
    KEY    = :foo
    VALUE  = 'bar'
    DATA   = Frivol::Helpers.dump_json({ KEY => VALUE })
    EXPIRY = 10 #seconds

    def test_ttl
      t = Class.new(TestClass) { storage_expires_in EXPIRY }.new
      assert_nil @backend.ttl(t.storage_key)

      @old_backend.set(t.storage_key, DATA)
      @old_backend.expire(t.storage_key, EXPIRY)
      assert_in_delta EXPIRY, @backend.ttl(t.storage_key), 2
    end

    def test_exists
      t = Class.new(TestClass) { storage_expires_in EXPIRY }.new
      refute @backend.exists(t.storage_key)

      @old_backend.set(t.storage_key, DATA)
      assert @backend.exists(t.storage_key)
    end

    def test_exists_after_expire
      t = Class.new(TestClass) { storage_expires_in -1 }.new
      @old_backend.set(t.storage_key, DATA, -1)
      assert_nil @backend.exists(t.storage_key)
    end

    def test_get
      t = TestClass.new
      @old_backend.set(t.storage_key, DATA, EXPIRY)
      assert_equal DATA, @backend.get(t.storage_key)
      assert_in_delta EXPIRY, @backend.ttl(t.storage_key), 2
      # Because get migrates
      assert @new_backend.exists(t.storage_key)
      refute @old_backend.exists(t.storage_key)
    end

    def test_retrieve
      t = Class.new(TestClass) { storage_expires_in EXPIRY }.new
      @old_backend.set(t.storage_key, DATA, EXPIRY)
      assert_equal VALUE, t.retrieve(KEY => false)
      # Because get migrates
      assert_in_delta EXPIRY, @backend.ttl(t.storage_key), 2
      assert_in_delta EXPIRY, @new_backend.ttl(t.storage_key), 2
      assert @new_backend.exists(t.storage_key)
      refute @old_backend.exists(t.storage_key)
    end

    def test_get_with_bucket
      t = Class.new(TestClass) { storage_bucket :diamonds, :expires_in => EXPIRY }.new
      @old_backend.set(t.storage_key(:diamonds), DATA, EXPIRY)
      assert_equal DATA, @backend.get(t.storage_key(:diamonds))
      # Because get migrates
      assert_in_delta EXPIRY, @backend.ttl(t.storage_key(:diamonds)), 2
      assert_in_delta EXPIRY, @new_backend.ttl(t.storage_key(:diamonds)), 2
      assert @new_backend.exists(t.storage_key(:diamonds))
      refute @old_backend.exists(t.storage_key(:diamonds))
    end

    def test_retrieve_with_bucket
      t = Class.new(TestClass) { storage_bucket :sapphires, :expires_in => EXPIRY }.new
      @old_backend.set(t.storage_key(:sapphires), DATA, EXPIRY)
      assert_equal VALUE, t.retrieve_sapphires(KEY => false)
      # Because get migrates
      assert_in_delta EXPIRY, @backend.ttl(t.storage_key(:sapphires)), 2
      assert_in_delta EXPIRY, @new_backend.ttl(t.storage_key(:sapphires)), 2
      assert @new_backend.exists(t.storage_key(:sapphires))
      refute @old_backend.exists(t.storage_key(:sapphires))
    end

    def test_set
      t = TestClass.new
      @old_backend.set(t.storage_key, DATA, EXPIRY)
      @backend.set(t.storage_key, DATA, EXPIRY)
      assert_equal DATA, @backend.get(t.storage_key)
      assert_in_delta EXPIRY, @backend.ttl(t.storage_key), 2
      assert_in_delta EXPIRY, @new_backend.ttl(t.storage_key), 2
      assert_nil @old_backend.ttl(t.storage_key)
      # Because set deletes from old backends
      assert @new_backend.exists(t.storage_key)
      refute @old_backend.exists(t.storage_key)
    end

    def test_store
      t = Class.new(TestClass) { storage_expires_in EXPIRY }.new
      @old_backend.set(t.storage_key, DATA, EXPIRY)
      t.store KEY => VALUE
      assert_equal VALUE, t.retrieve(KEY => false)
      assert_in_delta EXPIRY, @backend.ttl(t.storage_key), 2
      assert_in_delta EXPIRY, @new_backend.ttl(t.storage_key), 2
      assert_nil @old_backend.ttl(t.storage_key)
      # Because set deletes from old backends
      assert @new_backend.exists(t.storage_key)
      refute @old_backend.exists(t.storage_key)
    end

    def test_set_with_bucket
      t = Class.new(TestClass) { storage_bucket :garnets, :expires_in => EXPIRY }.new
      @old_backend.set(t.storage_key(:garnets), DATA, EXPIRY)
      @backend.set(t.storage_key(:garnets), DATA, EXPIRY)
      assert_equal DATA, @backend.get(t.storage_key(:garnets))
      assert_in_delta EXPIRY, @backend.ttl(t.storage_key(:garnets)), 2
      assert_in_delta EXPIRY, @new_backend.ttl(t.storage_key(:garnets)), 2
      assert_nil @old_backend.ttl(t.storage_key(:garnets))
      # Because set deletes from old backends
      assert @new_backend.exists(t.storage_key(:garnets))
      refute @old_backend.exists(t.storage_key(:garnets))
    end

    def test_store_with_bucket
      t = Class.new(TestClass) { storage_bucket :topaz, :expires_in => EXPIRY }.new
      @old_backend.set(t.storage_key(:topaz), DATA, EXPIRY)
      t.store_topaz KEY => VALUE
      assert_equal VALUE, t.retrieve_topaz(KEY => false)
      assert_in_delta EXPIRY, @backend.ttl(t.storage_key(:topaz)), 2
      assert_in_delta EXPIRY, @new_backend.ttl(t.storage_key(:topaz)), 2
      assert_nil @old_backend.ttl(t.storage_key(:topaz))
      # Because set deletes from old backends
      assert @new_backend.exists(t.storage_key(:topaz))
      refute @old_backend.exists(t.storage_key(:topaz))
    end
  end
end