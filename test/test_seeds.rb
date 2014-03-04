require "#{File.expand_path(File.dirname(__FILE__))}/helper.rb"

class TestSeeds < Test::Unit::TestCase
  def test_use_seed_value_for_initial_value_of_increment
    t = Class.new(TestClass) do
      storage_bucket :cached_count, :counter => true, :seed => Proc.new { |obj| obj.tedious_count }

      def tedious_count
        99_999 # ... bottle of beers on the wall
      end
    end.new

    assert_equal t.tedious_count + 1, t.increment_cached_count
  end

  def test_use_seed_value_for_initial_value_of_increment_by
    t = Class.new(TestClass) do
      storage_bucket :cached_count, :counter => true, :seed => Proc.new { |obj| obj.tedious_count }

      def tedious_count
        99_999 # ... bottle of beers on the wall
      end
    end.new

    amount = 2
    assert_equal t.tedious_count + amount, t.increment_cached_count_by(amount)
  end

  def test_use_seed_value_for_initial_value_of_decrement
    t = Class.new(TestClass) do
      storage_bucket :cached_count, :counter => true, :seed => Proc.new { |obj| obj.tedious_count }

      def tedious_count
        99_999 # ... bottle of beers on the wall
      end
    end.new

    assert_equal t.tedious_count - 1, t.decrement_cached_count
  end

  def test_use_seed_value_for_initial_value_of_decrement_by
    t = Class.new(TestClass) do
      storage_bucket :cached_count, :counter => true, :seed => Proc.new { |obj| obj.tedious_count }

      def tedious_count
        99_999 # ... bottle of beers on the wall
      end
    end.new

    amount = 3
    assert_equal t.tedious_count - amount, t.decrement_cached_count_by(amount)
  end
end