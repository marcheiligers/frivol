require "#{File.expand_path(File.dirname(__FILE__))}/helper.rb"

class TestBackends < Test::Unit::TestCase
  def test_ttl
    t = TestClass.new
    assert_nil @backend.ttl(t.storage_key)

    t.store :something => 'somewhere'
    assert_nil @backend.ttl(t.storage_key)

    t.expire_storage 10
    assert_in_delta 10, @backend.ttl(t.storage_key), 2
  end

  def test_exists
    t = TestClass.new
    refute @backend.exists(t.storage_key)

    t.store :something => 'somewhere'
    assert @backend.exists(t.storage_key)

    t.delete_storage
    refute @backend.exists(t.storage_key)
  end

  def test_exists_with_expiry
    t = Class.new(TestClass) { storage_expires_in -1 }.new
    refute @backend.exists(t.storage_key)

    t.store :something => 'somewhere'
    refute @backend.exists(t.storage_key)
  end
end