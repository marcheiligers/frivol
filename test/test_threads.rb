require "#{File.expand_path(File.dirname(__FILE__))}/helper.rb"
require "thread"

class TestThreads < Test::Unit::TestCase
  def test_each_thread_gets_its_own_connection
    threads = []
    queue = Queue.new
    2.times do
      threads << Thread.new do
        t = TestClass.new
        t.retrieve :nothing => nil
        queue << @backend.connection
      end
    end
    threads.each { |thread| thread.join }
    connection1 = queue.pop
    connection2 = queue.pop
    assert_not_equal connection2, connection1
  end
end