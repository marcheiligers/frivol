require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'mocha'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'frivol'

class Test::Unit::TestCase
  def fake_redis
    require 'fake_redis'
  end
  
  def ruby_one_eight?
    @ruby_one_eight || `ruby -v`.include?('1.8')
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
    retrieve :value => "default"
  end
end