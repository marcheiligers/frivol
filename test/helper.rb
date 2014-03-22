require 'rubygems'
require 'test/unit'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'frivol'

class Test::Unit::TestCase
  def setup
    # fake_redis # Comment out this line to test against a real live Redis
    # Frivol::Config.redis_config = { :db => 10 } # This will connect to a default Redis setup, otherwise set to { :host => "localhost", :port => 6379 }, for example
    # Frivol::Config.redis.flushdb

    # require 'frivol/backend/redis'
    # @backend = Frivol::Backend::Redis.new(:db => 10)
    # @backend.flushdb
    # Frivol::Config.backend = @backend

    require 'frivol/backend/riak'
    Riak.disable_list_keys_warnings = true
    @backend = Frivol::Backend::Riak.new(:protocol => 'http', :nodes => [ { :host => '127.0.0.1' } ])
    @backend.flushdb
    Frivol::Config.backend = @backend
  end

  def teardown
    @backend.flushdb
  end

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
end