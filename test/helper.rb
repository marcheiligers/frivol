require 'rubygems'
require 'test/unit'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'frivol'

class Test::Unit::TestCase
  def setup
    case ENV['backend']
    when 'redis'
      require 'frivol/backend/redis'
      @backend = Frivol::Backend::Redis.new(:db => 10)
      @backend.flushdb
      Frivol::Config.backend = @backend
    when 'riak'
      require 'frivol/backend/riak'
      I18n.enforce_available_locales = false
      Riak.disable_list_keys_warnings = true
      @backend = Frivol::Backend::Riak.new(:protocol => 'http', :nodes => [ { :host => '127.0.0.1' } ])
      @backend.flushdb
      Frivol::Config.backend = @backend
    else
      require 'frivol/backend/redis'
      fake_redis # Comment out this line to test against a real live Redis
      @backend = Frivol::Backend::Redis.new(:db => 10)
      @backend.flushdb
      Frivol::Config.backend = @backend
    end
    # NOTE: Because some backends like Riak are eventually consistent,
    #   we're changing the id of the test class per test.
    @test_id = TestClass.incr_id
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

  @@id = 1

  def self.incr_id
    @@id += 1
  end

  def id
    @@id
  end
end