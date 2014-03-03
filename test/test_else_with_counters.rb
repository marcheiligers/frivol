require "#{File.expand_path(File.dirname(__FILE__))}/helper.rb"

class TestElseWithCounters < Test::Unit::TestCase
  def test_given_CONDITION_evaluates_to_true_ELSE_is_not_performed
    else_proc = Proc.new{raise StandardError.new('You\'ll never catch me!') }
    t = Class.new(TestClass) { storage_bucket :stars, :counter => true, :condition => Proc.new{true}, :else => else_proc }.new

    assert_nothing_raised do
      t.increment_stars
      assert_equal 1, t.retrieve_stars(0)
    end
  end

  def test_given_CONDITION_evaluates_to_false_ELSE_is_performed
    else_proc = Proc.new{ |instance, method_name, *args| raise StandardError.new('You\'ll never catch me!') if method_name == 'increment_stars' }
    t = Class.new(TestClass) { storage_bucket :stars, :counter => true, :condition => Proc.new{false}, :else => else_proc }.new

    assert_raises StandardError do
      t.increment_stars
    end

    assert_equal 0, t.retrieve_stars(0)
  end

  def test_given_CONDITION_evaluates_to_false_ELSE_calls_a_method_on_the_object
    klass = Class.new(TestClass) do
      condition_proc = Proc.new{ |instance, method_name, *args| method_name != 'increment_stars'}
      storage_bucket :stars, :counter => true, :condition => condition_proc, :else => :set_stars_to_20

      def set_stars_to_20(frivol_method, *args)
        store_stars 20
      end
    end
    t = klass.new

    t.increment_stars

    assert_equal 20, t.retrieve_stars(0)
  end
end
