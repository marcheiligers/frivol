require "#{File.expand_path(File.dirname(__FILE__))}/helper.rb"

class TestIfCounters < Test::Unit::TestCase
  def test_increments_a_counter_with_no_if_conditions
    t = Class.new(TestClass) { storage_bucket :stars, :counter => true }.new
    t.increment_stars
    assert_equal 1, t.retrieve_stars(0)
  end

  def test_increments_a_counter_if_IF_method_evaluates_to_true
    t = Class.new(TestClass) do
      storage_bucket :stars, :counter => true, :if => :something_truthy

      def something_truthy
        'Wax museum'
      end
    end.new

    t.increment_stars
    assert_equal 1, t.retrieve_stars(0)
  end

  def test_increments_a_counter_with_positive_if_condition
    t = Class.new(TestClass) { storage_bucket :stars, :counter => true, :if => Proc.new{true} }.new
    t.increment_stars
    assert_equal 1, t.retrieve_stars(0)
  end

  def test_increments_a_counter_with_positive_if_condition_proc_which_takes_an_instance
    t = Class.new(TestClass) do
      storage_bucket :stars, :counter => true, :if => Proc.new{ |o| o.something_truthy }

      def something_truthy
        'Wax museum'
      end
    end.new

    t.increment_stars
    assert_equal 1, t.retrieve_stars(0)
  end

  def test_does_not_increment_a_counter_with_negative_if_condition
    t = Class.new(TestClass) { storage_bucket :stars,:counter => true, :if => Proc.new{false} }.new
    t.increment_stars
    assert_equal 0, t.retrieve_stars(0)
  end
end
