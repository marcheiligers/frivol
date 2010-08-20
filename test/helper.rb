require 'rubygems'
require 'test/unit'
require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'frivol'

class Test::Unit::TestCase
  def fake_redis
    require 'fake_redis'
  end
end

class TestClass
  include Frivol
  
  def id
    1
  end
  
  def save
    store :value => "value"
  end
  
  def load
    retrieve :value => "junk"
  end
end

