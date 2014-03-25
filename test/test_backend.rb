require "#{File.expand_path(File.dirname(__FILE__))}/helper.rb"

class TestFrivolize < Test::Unit::TestCase
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