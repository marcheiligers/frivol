require "#{File.expand_path(File.dirname(__FILE__))}/helper.rb"

class TestMultiBackendCounters < Test::Unit::TestCase
  if multi_test?
    KEY    = :foo
    VALUE  = 'bar'
    DATA   = Frivol::Helpers.dump_json({ KEY => VALUE })

    def test_ttl
      t = Class.new(TestClass) { storage_bucket :crows, :counter => true }.new
      assert_nil @backend.ttl(t.storage_key(:crows))

      @old_backend.setc(t.storage_key(:crows), 1)
      assert_nil @backend.ttl(t.storage_key(:crows))
    end

    def test_exists
      t = Class.new(TestClass) { storage_bucket :doves, :counter => true }.new
      refute @backend.exists(t.storage_key(:doves))

      @old_backend.setc(t.storage_key(:doves), 1)
      assert @backend.exists(t.storage_key(:doves))
    end

    def test_getc
      t = Class.new(TestClass) { storage_bucket :parrots, :counter => true }.new
      @old_backend.setc(t.storage_key(:parrots), 1)
      assert_equal 1, @backend.getc(t.storage_key(:parrots))
      # Because get migrates
      assert @new_backend.exists(t.storage_key(:parrots))
      refute @old_backend.exists(t.storage_key(:parrots))
    end

    def test_retrieve
      t = Class.new(TestClass) { storage_bucket :lovebirds, :counter => true }.new
      @old_backend.set(t.storage_key(:lovebirds), 1)
      assert_equal 1, t.retrieve_lovebirds(KEY => false)
      # Because get migrates
      assert @new_backend.exists(t.storage_key(:lovebirds))
      refute @old_backend.exists(t.storage_key(:lovebirds))
    end

    def test_setc
      t = Class.new(TestClass) { storage_bucket :parakeets, :counter => true }.new
      @old_backend.setc(t.storage_key(:parakeets), 1)
      @backend.setc(t.storage_key(:parakeets), 2)
      assert_equal 2, @backend.getc(t.storage_key(:parakeets)).to_i
      # Because set deletes from old backends
      assert @new_backend.exists(t.storage_key(:parakeets))
      refute @old_backend.exists(t.storage_key(:parakeets))
    end

    def test_store
      t = Class.new(TestClass) { storage_bucket :macaws, :counter => true }.new
      @old_backend.set(t.storage_key(:macaws), 1)
      t.store_macaws 2
      assert_equal 2, t.retrieve_macaws(0)
      # Because set deletes from old backends
      assert @new_backend.exists(t.storage_key(:macaws))
      refute @old_backend.exists(t.storage_key(:macaws))
    end

    def test_increment
      t = Class.new(TestClass) { storage_bucket :cockatoos, :counter => true }.new
      @old_backend.set(t.storage_key(:cockatoos), 2)
      t.increment_cockatoos
      assert_equal 3, t.retrieve_cockatoos(0)
      # Because set deletes from old backends
      assert @new_backend.exists(t.storage_key(:cockatoos))
      refute @old_backend.exists(t.storage_key(:cockatoos))
    end

    def test_increment_by
      t = Class.new(TestClass) { storage_bucket :canaries, :counter => true }.new
      @old_backend.set(t.storage_key(:canaries), 3)
      t.increment_canaries_by(6)
      assert_equal 9, t.retrieve_canaries(0)
      # Because set deletes from old backends
      assert @new_backend.exists(t.storage_key(:canaries))
      refute @old_backend.exists(t.storage_key(:canaries))
    end

    def test_decrement
      t = Class.new(TestClass) { storage_bucket :budgies, :counter => true }.new
      @old_backend.set(t.storage_key(:budgies), 7)
      t.decrement_budgies
      assert_equal 6, t.retrieve_budgies(0)
      # Because set deletes from old backends
      assert @new_backend.exists(t.storage_key(:budgies))
      refute @old_backend.exists(t.storage_key(:budgies))
    end

    def test_decrement_by
      t = Class.new(TestClass) { storage_bucket :finches, :counter => true }.new
      @old_backend.set(t.storage_key(:finches), 8)
      t.decrement_finches_by(2)
      assert_equal 6, t.retrieve_finches(0)
      # Because set deletes from old backends
      assert @new_backend.exists(t.storage_key(:finches))
      refute @old_backend.exists(t.storage_key(:finches))
    end

  end
end