require "#{File.expand_path(File.dirname(__FILE__))}/helper.rb"

class TestCounters < Test::Unit::TestCase
  def test_be_able_to_create_counter_buckets
    t = Class.new(TestClass) { storage_bucket :blue, :counter => true }.new

    assert t.respond_to?(:store_blue)
    assert t.respond_to?(:retrieve_blue)
    assert t.respond_to?(:increment_blue)
  end

  def test_store_increment_and_retrieve_integers_in_a_counter
    t = Class.new(TestClass) { storage_bucket :blue, :counter => true }.new
    t.store_blue 10

    assert_equal 10, t.retrieve_blue(0)
    assert_equal 11, t.increment_blue
    assert_equal 11, t.retrieve_blue(0)
  end

  def test_increment_by_and_retrieve_integers_in_a_counter
    t = Class.new(TestClass) do
      storage_bucket :cats, :counter => true

      def kittens
        increment_cats_by 5
      end
    end.new

    t.store_cats 1
    assert_equal 1, t.retrieve_cats(0)
    t.kittens
    assert_equal 6, t.retrieve_cats(0)
  end

  def test_store_decrement_and_retrieve_integers_in_a_counter
    t = Class.new(TestClass) { storage_bucket :red, :counter => true }.new

    assert_equal 0, t.retrieve_red(0)
    t.store_red(10)
    assert_equal 10, t.retrieve_red(0)
    assert_equal 9, t.decrement_red
    assert_equal 9, t.retrieve_red(0)
  end

  def test_decrement_by_and_retrieve_integers_in_a_counter
    t = Class.new(TestClass) do
      storage_bucket :money, :counter => true

      def shopping
        decrement_money_by 1000
      end
    end.new

    t.store_money 2000
    assert_equal 2000, t.retrieve_money(0)
    t.shopping
    assert_equal 1000, t.retrieve_money(0)
  end

  def test_set_expiry_on_counters
    klass = Class.new(TestClass) { storage_bucket :sheep, :counter => true, :expires_in => 1 }
    klass.new
    assert_equal 1, klass.storage_expiry(:sheep)
  end

  def test_expire_a_counter_bucket
    t = Class.new(TestClass) { storage_bucket :yellow, :counter => true, :expires_in => -1 }.new
    t.store_yellow 10
    assert_equal 0, t.retrieve_yellow(0)
  end
end