require "#{File.expand_path(File.dirname(__FILE__))}/helper.rb"

class TestFrivol < Test::Unit::TestCase
  def test_have_a_default_storage_key_made_up_of_the_class_name_and_id
    t = TestClass.new
    assert_equal "TestClass-#{@test_id}", t.storage_key
  end

  def test_store_and_retrieve_data
    t = TestClass.new
    t.store :value => 'value'
    assert_equal "value", t.retrieve(:value => 'default')
  end

  def test_retrieve_non_existing
    t = TestClass.new
    assert_nothing_raised do
      assert_nil t.retrieve(:nothing => nil)
    end
  end

  def test_return_a_default_for_a_value_thats_not_in_storage
    t = TestClass.new
    assert_equal "default", t.retrieve(:value => 'default')
  end

  def test_save_and_retrieve_multiple_values
    t = TestClass.new
    t.store :val1 => 1, :val2 => 2

    r = t.retrieve :val1 => nil, :val2 => nil
    if ruby_one_eight?
      assert r == [ 1, 2 ] || r == [ 2, 1 ] # yuck!
    else
      # Ruby 1.8 may fail this because hash keys do not guarantee order
      assert_equal [ 1, 2 ], r
    end
  end

  def test_get_defaults_from_instance_methods_if_defined
    t = Class.new(TestClass) do
      def value2_default
        "value2"
      end
    end.new

    result = t.retrieve :value => nil, :value2 => :value2_default
    assert_equal [ "", "value2" ], result.map(&:to_s).sort
  end

  def test_not_be_naughty_and_try_to_respond_to_nil_default
    t = TestClass.new
    assert_equal nil, t.retrieve(:value => nil)
  end

  def test_only_try_respond_to_symbol_defaults
    t = Class.new(TestClass) do
      def load
        retrieve :value => "load", :def_val => :default_value # yes, that's right, we would cause a stack overflow here
      end

      def default_value
        "yay!"
      end
    end.new

    assert_equal [ "load", "yay!" ], t.load.sort
  end

  def test_be_able_to_override_the_key_method
    t = Class.new(TestClass) do
      def storage_key(bucket = nil)
        "my_storage"
      end
    end.new

    t.store :value => 'value'
    assert @backend.get("my_storage")
  end

  def test_retain_Times_as_Times
    t = TestClass.new
    t.store :t => Time.local(2010, 8, 20)
    assert_equal Time.local(2010, 8, 20), t.retrieve(:t => nil)
  end

  def test_expires_should_not_throw_nasty_errors
    t = TestClass.new
    t.store :value => 'value'
    t.expire_storage -1

    t = TestClass.new # Get a fresh instance so that the @frivol_data is empty
    assert_equal "default", t.retrieve(:value => 'default')
  end

  def test_use_default_expiry_set_on_the_class
    klass = Class.new(TestClass) { storage_expires_in -10 }
    t = klass.new
    t.store :value => 'value'

    t = klass.new # Get a fresh instance so that the @frivol_data is empty
    assert_equal "default", t.retrieve(:value => 'default')
  end

  # In older versions of Redis, if you save a value to a volatile key, the expiry is cleared
  # TODO: test against older Redis and remove re-expiring for versions that don't need it
  def test_resaving_a_value_should_not_clear_the_expiry
    t = Class.new(TestClass) { storage_expires_in 2 }.new

    t.store :value => 'value'
    assert @backend.ttl(t.storage_key) > 0

    t.store :value => 'value' # a second time
    assert @backend.ttl(t.storage_key) > 0
  end

  def test_be_able_to_include_in_other_classes_with_storage_expiry
    klass = Class.new
    Frivol::Config.include_in(klass, 30)
    t = klass.new
    assert t.respond_to? :store
    assert_equal 30, klass.storage_expiry
  end

  def test_return_the_already_loaded_hash_if_its_already_loaded
    t = TestClass.new
    t.retrieve :value => 'default'

    # ensure we're getting the result from the cache and not Redis
    def @backend.get(key); raise 'Onoes, loaded again'; end

    t.retrieve :value => 'default'
  end

  def test_be_able_to_delete_storage
    t = TestClass.new
    t.store :value => ''
    t.delete_storage
    assert_equal "default", t.retrieve(:value => 'default')
  end

  def test_be_able_to_clear_cached_storage_for_a_bucket
    t = Class.new(TestClass) { storage_bucket :gold }.new
    t.store_gold :value => "value"
    value = t.retrieve_gold :value => "default"
    assert_equal "value", value

    t.clear_gold

    # ensure we're getting the result from Redis and not the cache
    def @backend.get(key, expiry = nil)
      MultiJson.dump(:value => 'this is what we want')
    end

    value = t.retrieve_gold :value => "default"
    assert_equal "this is what we want", value
  end

end
