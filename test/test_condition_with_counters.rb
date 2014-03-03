require "#{File.expand_path(File.dirname(__FILE__))}/helper.rb"

class TestIfCounters < Test::Unit::TestCase
  def test_increments_a_counter_with_no_conditions
    t = Class.new(TestClass) { storage_bucket :stars, :counter => true }.new
    t.increment_stars
    assert_equal 1, t.retrieve_stars(0)
  end

  def test_increments_a_counter_if_condition_evaluates_to_true
    klass = Class.new(TestClass) do
      storage_bucket :stars, :counter => true, :condition => :something_truthy

      def something_truthy(frivol_method, *args)
        'Wax museum'
      end
    end
    t = klass.new

    t.increment_stars
    assert_equal 1, t.retrieve_stars(0)
  end

  def test_increments_a_counter_with_positive_condition
    t = Class.new(TestClass) { storage_bucket :stars, :counter => true, :condition => Proc.new{true} }.new
    t.increment_stars
    assert_equal 1, t.retrieve_stars(0)
  end

  def test_increments_a_counter_when_condition_is_a_proc
    klass = Class.new(TestClass) do
      storage_bucket :stars, :counter => true, :condition => Proc.new{ |instance, frivol_method, *args| instance.something_truthy }

      def something_truthy
        'Wax museum'
      end
    end
    t = klass.new

    t.increment_stars
    assert_equal 1, t.retrieve_stars(0)
  end

  def test_does_not_increment_a_counter_with_negative_condition
    t = Class.new(TestClass) { storage_bucket :stars,:counter => true, :condition => Proc.new{false} }.new
    t.increment_stars
    assert_equal 0, t.retrieve_stars(0)
  end

  def test_does_not_increment_a_counter_when_condition_is_false
    t = Class.new(TestClass) { storage_bucket :stars,:counter => true, :condition => false }.new
    t.increment_stars
    assert_equal 0, t.retrieve_stars(0)
  end

  def test_increment_by_does_not_increment_with_condition_is_false
    t = Class.new(TestClass) { storage_bucket :stars,:counter => true, :condition => false }.new
    t.increment_stars_by(20)
    assert_equal 0, t.retrieve_stars(0)
  end
end
