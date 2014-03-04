require "#{File.expand_path(File.dirname(__FILE__))}/helper.rb"

class TestBuckets < Test::Unit::TestCase
  def test_be_able_to_create_and_use_buckets
    t = Class.new(TestClass) { storage_bucket :blue }.new

    assert t.respond_to?(:store_blue)
    assert t.respond_to?(:retrieve_blue)
  end

  def test_store_different_values_in_different_buckets
    t = Class.new(TestClass) { storage_bucket :blue }.new

    t.store :value => 'value'
    t.store_blue :value => 'blue value'

    assert_equal "value", t.retrieve(:value => 'default')
    assert_equal "blue value", t.retrieve_blue(:value => 'default')
  end

  def test_be_able_to_delete_storage_for_a_bucket
    t = Class.new(TestClass) { storage_bucket :silver }.new
    t.store_silver :value => 'value'
    assert_equal "value", t.retrieve_silver(:value => 'default')
    t.delete_silver
    assert_equal "default", t.retrieve_silver(:value => 'default')
  end

  def test_have_different_expiry_times_for_different_buckets
    klass = Class.new(TestClass) do
      storage_bucket :blue, :expires_in => 1
      storage_expires_in 2
    end

    assert_equal 1, klass.storage_expiry(:blue)
    assert_equal 2, klass.storage_expiry
  end

  def test_expire_data_in_buckets
    klass = Class.new(TestClass) do
      storage_bucket :blue, :expires_in => -1
      storage_expires_in 1
    end

    t = klass.new
    t.store :value => 'value'
    t.store_blue :value => 'value'

    t = klass.new # get a new instance so @frivol_data is empty
    assert_equal "value", t.retrieve(:value => 'default')
    assert_equal "blue default", t.retrieve_blue(:value => 'blue default')
  end
end