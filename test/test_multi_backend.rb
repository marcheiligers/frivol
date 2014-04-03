require "#{File.expand_path(File.dirname(__FILE__))}/helper.rb"

class TestMultiBackend < Test::Unit::TestCase
  if multi_test?
    KEY    = :foo
    VALUE  = 'bar'
    DATA   = Frivol::Helpers.dump_json({ KEY => VALUE })

    def test_backends_must_be_uniq
      assert_raises Frivol::Backend::Multi::BackendsNotUniqueError do
        Frivol::Backend::Multi.new([ @old_backend, @old_backend ])
      end

      assert_raises Frivol::Backend::Multi::BackendsNotUniqueError do
        Frivol::Backend::Multi.new([ @new_backend, @new_backend ])
      end
    end

    def test_ttl
      t = TestClass.new
      assert_nil @backend.ttl(t.storage_key)

      @old_backend.set(t.storage_key, DATA)
      assert_nil @backend.ttl(t.storage_key)
    end

    def test_exists
      t = TestClass.new
      refute @backend.exists(t.storage_key)

      @old_backend.set(t.storage_key, DATA)
      assert @backend.exists(t.storage_key)
    end

    def test_del
      t = TestClass.new
      @old_backend.set(t.storage_key, DATA)
      assert @backend.exists(t.storage_key)
      @backend.del(t.storage_key)
      refute @backend.exists(t.storage_key)
      refute @old_backend.exists(t.storage_key)
    end

    def test_get
      t = TestClass.new
      @old_backend.set(t.storage_key, DATA)
      assert_equal DATA, @backend.get(t.storage_key)
      # Because get migrates
      assert @new_backend.exists(t.storage_key)
      refute @old_backend.exists(t.storage_key)
    end

    def test_retrieve_non_existing
      t = TestClass.new
      assert_nothing_raised do
        assert_nil t.retrieve(:nothing => nil)
      end
    end

    def test_retrieve
      t = TestClass.new
      @old_backend.set(t.storage_key, DATA)
      assert_equal VALUE, t.retrieve(KEY => false)
      # Because get migrates
      assert @new_backend.exists(t.storage_key)
      refute @old_backend.exists(t.storage_key)
    end

    def test_get_with_bucket
      t = Class.new(TestClass) { storage_bucket :diamonds }.new
      @old_backend.set(t.storage_key(:diamonds), DATA)
      assert_equal DATA, @backend.get(t.storage_key(:diamonds))
      # Because get migrates
      assert @new_backend.exists(t.storage_key(:diamonds))
      refute @old_backend.exists(t.storage_key(:diamonds))
    end

    def test_retrieve_with_bucket
      t = Class.new(TestClass) { storage_bucket :sapphires }.new
      @old_backend.set(t.storage_key(:sapphires), DATA)
      assert_equal VALUE, t.retrieve_sapphires(KEY => false)
      # Because get migrates
      assert @new_backend.exists(t.storage_key(:sapphires))
      refute @old_backend.exists(t.storage_key(:sapphires))
    end

    def test_set
      t = TestClass.new
      @old_backend.set(t.storage_key, DATA)
      @backend.set(t.storage_key, DATA)
      assert_equal DATA, @backend.get(t.storage_key)
      # Because set deletes from old backends
      assert @new_backend.exists(t.storage_key)
      refute @old_backend.exists(t.storage_key)
    end

    def test_store
      t = TestClass.new
      @old_backend.set(t.storage_key, DATA)
      t.store KEY => VALUE
      assert_equal VALUE, t.retrieve(KEY => false)
      # Because set deletes from old backends
      assert @new_backend.exists(t.storage_key)
      refute @old_backend.exists(t.storage_key)
    end

    def test_set_with_bucket
      t = Class.new(TestClass) { storage_bucket :garnets }.new
      @old_backend.set(t.storage_key(:garnets), DATA)
      @backend.set(t.storage_key(:garnets), DATA)
      assert_equal DATA, @backend.get(t.storage_key(:garnets))
      # Because set deletes from old backends
      assert @new_backend.exists(t.storage_key(:garnets))
      refute @old_backend.exists(t.storage_key(:garnets))
    end

    def test_store_with_bucket
      t = Class.new(TestClass) { storage_bucket :topaz }.new
      @old_backend.set(t.storage_key(:topaz), DATA)
      t.store_topaz KEY => VALUE
      assert_equal VALUE, t.retrieve_topaz(KEY => false)
      # Because set deletes from old backends
      assert @new_backend.exists(t.storage_key(:topaz))
      refute @old_backend.exists(t.storage_key(:topaz))
    end
  end
end