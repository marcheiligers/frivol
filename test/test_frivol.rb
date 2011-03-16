require "#{File.expand_path(File.dirname(__FILE__))}/helper.rb"

class TestFrivol < Test::Unit::TestCase
  def setup 
    fake_redis # Comment out this line to test against a real live Redis
    Frivol::Config.redis_config = { :thread_safe => true } # This will connect to a default Redis setup, otherwise set to { :host => "localhost", :port => 6379 }, for example
    Frivol::Config.redis.flushdb
  end
  
  def teardown
    # puts Frivol::Config.redis.inspect
    Frivol::Config.redis.flushdb
  end
  
  should "have a default storage key made up of the class name and id" do
    t = TestClass.new
    assert_equal "TestClass-1", t.storage_key
  end
  
  should "store and retrieve data" do
    t = TestClass.new
    t.save
    assert_equal "value", t.load
  end
  
  should "return a default for a value that's not in storage" do
    t = TestClass.new
    assert_equal "default", t.load
  end
  
  should "save and retrieve multiple values" do
    class MultiTestClass < TestClass
      def save
        store :val1 => 1, :val2 => 2
      end
      
      def load
        retrieve :val1 => nil, :val2 => nil
      end
    end
    
    t = MultiTestClass.new
    t.save
    assert_equal [ 1, 2 ], t.load
  end
  
  should "get defaults from instance methods if defined" do
    class DefaultsTestClass < TestClass
      def load
        retrieve :value => nil, :value2 => :value2_default
      end
      
      def value2_default
        "value2"
      end
    end
    
    t = DefaultsTestClass.new
    t.save
    assert_equal [ "value", "value2" ], t.load.sort
  end
  
  should "not be naughty and try to respond to nil default" do
    class DefaultNilTestClass < TestClass
      def load
        retrieve :value => nil
      end
    end
  
    t = DefaultNilTestClass.new
    assert_equal nil, t.load
  end

  should "only try respond to symbol defaults" do
    class DefaultNonSymbolTestClass < TestClass
      def load
        retrieve :value => "load", :def_val => :default_value # yes, that's right, we would cause a stack overflow here
      end
      
      def default_value
        "yay!"
      end
    end
  
    t = DefaultNonSymbolTestClass.new
    assert_equal [ "load", "yay!" ], t.load.sort
  end

  should "be able to override the key method" do
    class OverrideKeyTestClass < TestClass
      def storage_key(bucket = nil)
        "my_storage"
      end
    end
    
    t = OverrideKeyTestClass.new
    t.save
    assert_equal "value", t.load
    assert Frivol::Config.redis["my_storage"]
  end
  
  should "retain Times as Times" do
    class TimeTestClass < TestClass
      def save
        store :t => Time.local(2010, 8, 20)
      end
      
      def load
        retrieve :t => nil
      end
    end
  
    t = TimeTestClass.new
    t.save
    assert_equal Time.local(2010, 8, 20), t.load
  end
  
  should "expire storage the everytime time it's stored" do
    class ExpiryTestClass < TestClass
      storage_expires_in 60
    end
    
    Frivol::Config.redis.expects(:expire).twice
    Frivol::Config.redis.expects(:ttl).once
    t = ExpiryTestClass.new
    t.load
    t.save
    t = ExpiryTestClass.new # get a new one
    t.save
  end
  
  should "expires should not throw nasty errors" do
    t = TestClass.new
    t.save
    t.expire_storage 1
    sleep 1
    t = TestClass.new # Get a fresh instance so that the @frivol_data is empty
    assert_equal "default", t.load
  end
  
  should "use default expiry set on the class" do
    class ExpiryTestClass < TestClass
      storage_expires_in 1
    end
    t = ExpiryTestClass.new
    t.save
    sleep 1
    t = ExpiryTestClass.new # Get a fresh instance so that the @frivol_data is empty
    assert_equal "default", t.load
  end

  # If you save a value to a volatile key, the expiry is cleared
  should "resaving a value should not clear the expiry" do
    class ResavingExpiryTestClass < TestClass
      storage_expires_in 2
    end
    t = ResavingExpiryTestClass.new
    t.save
    assert Frivol::Config.redis.ttl(t.storage_key) > 0
    t.save # a second time
    assert Frivol::Config.redis.ttl(t.storage_key) > 0
  end
  
  should "be able to include in other classes with storage expiry" do
    class BlankTestClass
    end
    Frivol::Config.include_in(BlankTestClass, 30)
    t = BlankTestClass.new
    assert t.respond_to? :store
    assert_equal 30, BlankTestClass.storage_expiry
  end
  
  should "return the already loaded hash if it's already loaded" do
    Frivol::Config.redis.expects(:[]).once
    t = TestClass.new
    t.load
    t.load
  end
  
  should "be able to delete storage" do
    t = TestClass.new
    t.save
    t.delete_storage
    assert_equal "default", t.load
  end
  
  should "be able to create and use buckets" do
    class SimpleBucketTestClass < TestClass
      storage_bucket :blue
    end
    t = SimpleBucketTestClass.new
    assert t.respond_to?(:store_blue)
    assert t.respond_to?(:retrieve_blue)
  end
  
  should "store different values in different buckets" do
    class StorageBucketTestClass < TestClass
      storage_bucket :blue
      
      def save_blue
        store_blue :value => "blue value"
      end
      
      def load_blue
        retrieve_blue :value => "blue default"
      end
    end
    t = StorageBucketTestClass.new
    t.save
    t.save_blue
    assert_equal "value", t.load
    assert_equal "blue value", t.load_blue
  end

  should "have different expiry times for different buckets" do
    class ExpireBucketsTestClass < TestClass
      storage_bucket :blue, :expires_in => 1
      storage_expires_in 2
    end
    t = ExpireBucketsTestClass.new
    assert_equal 1, ExpireBucketsTestClass.storage_expiry(:blue)
    assert_equal 2, ExpireBucketsTestClass.storage_expiry
  end

  should "expire data in buckets" do
    class ExpireBucketsTestClass < TestClass
      storage_bucket :blue, :expires_in => 1
      storage_expires_in 2
      
      def save_blue
        store_blue :value => "blue value"
      end
      
      def load_blue
        retrieve_blue :value => "blue default"
      end
    end
    t = ExpireBucketsTestClass.new
    t.save
    t.save_blue
    sleep 1
    t = ExpireBucketsTestClass.new # get a new instance so @frivol_data is empty
    assert_equal "value", t.load
    assert_equal "blue default", t.load_blue
  end
  
  should "be able to create counter buckets" do
    class SimpleCounterTestClass < TestClass
      storage_bucket :blue, :counter => true
    end
    t = SimpleCounterTestClass.new
    assert t.respond_to?(:store_blue)
    assert t.respond_to?(:retrieve_blue)
    assert t.respond_to?(:increment_blue)
  end
  
  should "store, increment and retrieve integers in a counter" do
    class IncrCounterTestClass < TestClass
      storage_bucket :blue, :counter => true
      
      def save_blue
        store_blue 10
      end
      
      def load_blue
        retrieve_blue 0
      end
    end
    t = IncrCounterTestClass.new
    assert_equal 0, t.load_blue
    t.save_blue
    assert_equal 10, t.load_blue
    assert_equal 11, t.increment_blue
    assert_equal 11, t.load_blue
  end
  
  should "set expiry on counters" do
    class SetExpireCounterTestClass < TestClass
      storage_bucket :sheep_counter, :counter => true, :expires_in => 1
    end
    t = SetExpireCounterTestClass.new
    assert_equal 1, SetExpireCounterTestClass.storage_expiry(:sheep_counter)  
  end

  should "expire a counter bucket" do
    class ExpireCounterTestClass < TestClass
      storage_bucket :kitten_grave, :counter => true, :expires_in => 1

      def bury_kittens
        store_kitten_grave 10
      end
      
      def peek_in_grave
        retrieve_kitten_grave 0
      end
    end
    
    k = ExpireCounterTestClass.new
    k.bury_kittens
    assert_equal 10, k.peek_in_grave
    
    sleep(1.1)
    assert_equal 0, k.peek_in_grave  
  end

  # Note: this test will fail from time to time using fake_redis because fake_redis is not thread safe
  should "have thread safe counters" do
    class ThreadCounterTestClass < TestClass
      storage_bucket :blue, :counter => true
      
      def save_blue
        store_blue 10
      end
      
      def load_blue
        retrieve_blue 0
      end
    end
    t = ThreadCounterTestClass.new
    t.save_blue
    assert_equal 10, t.load_blue
    
    threads = []
    100.times do 
      threads << Thread.new do
        10.times do
          temp = ThreadCounterTestClass.new
          temp.increment_blue
          sleep(rand(10) / 100.0)
        end
      end
    end
    threads.each { |a| a.join }
      
    assert_equal 1010, t.load_blue
  end
  
  should "be able to delete storage for a bucket" do
    class DeleteBucketTestClass < TestClass
      storage_bucket :silver
      
      def save_silver
        store_silver :value => "value"
      end
      
      def load_silver
        retrieve_silver :value => "default"
      end
    end
    t = DeleteBucketTestClass.new
    t.save_silver
    assert_equal "value", t.load_silver
    t.delete_silver
    assert_equal "default", t.load_silver
  end
  
  should "be able to clear cached storage for a bucket" do
    class ClearBucketTestClass < TestClass
      storage_bucket :gold
      
      def save_gold
        store_gold :value => "value"
      end
      
      def load_gold
        retrieve_gold :value => "default"
      end
    end
    t = ClearBucketTestClass.new
    t.save_gold
    assert_equal "value", t.load_gold
    t.clear_gold
    # ensure we're getting the result from Redis and not the cache
    Frivol::Config.redis.expects(:[]).with(t.storage_key(:gold)).once.returns({ :value => "value" }.to_json)
    assert_equal "value", t.load_gold
  end
  
  
end
