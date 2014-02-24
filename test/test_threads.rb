require "#{File.expand_path(File.dirname(__FILE__))}/helper.rb"

class TestFrivol < Test::Unit::TestCase
  def test_each_thread_gets_its_own_connection
    threads = []
    2.times do
      threads << Thread.new do
        t = TestClass.new
        t.retrieve :nothing => nil
      end
    end
    threads.each { |thread| thread.join }
    assert_not_equal threads.first[:frivol_redis], threads.last[:frivol_redis]
  end
end