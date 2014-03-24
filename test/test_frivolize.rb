require "#{File.expand_path(File.dirname(__FILE__))}/helper.rb"

class TestFrivolize < Test::Unit::TestCase
  def test_frivolize_methods
    klass = Class.new(TestClass) do
      class_variable_set :@@count, 0 # Ruby 1.9.2 seems to need this
      @@count = 0

      # Imagine counting dinosuars takes a long time, what with the need to invent a time machine first and all
      def dinosaur_count
        @@count += 1
      end
      frivolize :dinosaur_count
    end

    t = klass.new
    assert t.methods.include?(ruby_one_eight? ? 'dinosaur_count' : :dinosaur_count)
    assert t.methods.include?(ruby_one_eight? ? 'frivolized_dinosaur_count' : :frivolized_dinosaur_count)

    assert_equal 1, t.dinosaur_count

    t = klass.new
    assert_equal 1, t.dinosaur_count # Does not call original method again

    t.delete_storage
    t = klass.new
    assert_equal 2, t.dinosaur_count # Calls the original again
  end

  def test_frivolize_methods_with_expiry_in_a_bucket
    klass = Class.new(TestClass) do
      class_variable_set :@@count, 0 # Ruby 1.9.2 seems to need this
      @@count = 0

      # Imagine counting dinosuars takes a long time, what with the need to invent a time machine first and all
      def dinosaurus_count
        @@count += 1
      end
      frivolize :dinosaurus_count, { :bucket => :dinosauruss, :expires_in => -1 }
    end

    t = klass.new
    assert_equal 1, t.dinosaurus_count
    assert_equal 1, t.dinosaurus_count # Still 10 because it's coming from the class cache

    t = klass.new
    assert_equal 2, t.dinosaurus_count
  end

  def test_frivolize_methods_with_expiry_as_a_counter
    klass = Class.new(TestClass) do
      class_variable_set :@@count, 0 # Ruby 1.9.2 seems to need this
      @@count = 0

      # Imagine counting dinosuars takes a long time, what with the need to invent a time machine first and all
      def dinosaurii_count
        @@count += 1
      end
      frivolize :dinosaurii_count, { :expires_in => -1, :counter => true }
    end

    t = klass.new
    assert t.methods.include?(ruby_one_eight? ? 'store_dinosaurii_count' : :store_dinosaurii_count) # check that the bucket name is the method name

    assert_equal 1, t.dinosaurii_count

    t = klass.new # a fresh instance after value expired
    assert_equal 2, t.dinosaurii_count
  end

  def test_frivolize_with_seed_as_a_counter_for_increment
    t = Class.new(TestClass) do
      def bak_baks
        88_888
      end
      frivolize :bak_baks, :counter => true, :seed => Proc.new{ |obj| obj.bak_baks }
    end.new

    assert_equal 88_888 + 1, t.increment_bak_baks
  end
end