require 'helper'

class TestFrivol < Test::Unit::TestCase
  def setup 
    fake_redis
    Frivol::Config.redis_config = {}
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
    assert_equal "junk", t.load
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
    assert_equal [ "value", "value2" ], t.load
  end

  should "be able to override the key method" do
    class OverrideKeyTestClass < TestClass
      def storage_key
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
  
  should "expire storage the first time it's stored" do
    class ExpiryTestClass < TestClass
      storage_expires_in 60
    end
    
    Frivol::Config.redis.expects(:expire).once
    t = ExpiryTestClass.new
    t.load
    t.save
    t.save
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
end
