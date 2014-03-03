require "#{File.expand_path(File.dirname(__FILE__))}/helper.rb"

class TestCondition < Test::Unit::TestCase
  def test_stores_if_CONDITION_method_evaluates_to_truthy
    klass = Class.new(TestClass) do
      storage_bucket :stars, :condition => :something_truthy

      def something_truthy(frivol_method, *args)
        'Wax museum'
      end
    end
    t = klass.new

    t.store_stars :value => 88
    assert_equal 88, t.retrieve_stars(:value => 0)
  end

  def test_stores_with_positive_CONDITION_proc
    t = Class.new(TestClass) { storage_bucket :stars, :condition => Proc.new{true} }.new
    t.store_stars :value => 77
    assert_equal 77, t.retrieve_stars(:value => 0)
  end

  def test_stores_positive_CONDITION_proc_which_takes_an_instance
    klass = Class.new(TestClass) do
      storage_bucket :stars, :condition => Proc.new{ |o| o.something_truthy }

      def something_truthy
        'Wax museum'
      end
    end
    t = klass.new

    t.store_stars :value => 66
    assert_equal 66, t.retrieve_stars(:value => 0)
  end

  def test_does_not_store_with_negative_CONDITION
    t = Class.new(TestClass) { storage_bucket :stars, :condition => Proc.new{false} }.new
    t.store_stars :value => 55
    assert_equal 0, t.retrieve_stars(:value => 0)
  end
end
