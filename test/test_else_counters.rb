require "#{File.expand_path(File.dirname(__FILE__))}/helper.rb"

class TestElseCounters < Test::Unit::TestCase
  def test_given_IF_evaluates_to_true_ELSE_is_not_performed
    else_proc = Proc.new{raise StandardError.new('You\'ll never catch me!') }
    t = Class.new(TestClass) { storage_bucket :stars, :counter => true, :if => Proc.new{true}, :else => else_proc }.new

    assert_nothing_raised do
      t.increment_stars
      assert_equal 1, t.retrieve_stars(0)
    end
  end

  def test_given_IF_evaluates_to_false_ELSE_is_performed
    else_proc = Proc.new{raise StandardError.new('You\'ll never catch me!') }
    t = Class.new(TestClass) { storage_bucket :stars, :counter => true, :if => Proc.new{false}, :else => else_proc }.new

    assert_raises StandardError do
      t.increment_stars
    end

    assert_equal 0, t.retrieve_stars(0)
  end

  def test_given_IF_evaluates_to_false_ELSE_calls_a_method_on_the_object
    klass = Class.new(TestClass) do
      storage_bucket :stars, :counter => true, :if => Proc.new{false}, :else => :set_stars_to_20

      def set_stars_to_20
        store_stars 20
      end
    end
    t = klass.new

    t.increment_stars

    assert_equal 20, t.retrieve_stars(0)
  end
end
