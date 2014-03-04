require "#{File.expand_path(File.dirname(__FILE__))}/helper.rb"

class TestExtensions < Test::Unit::TestCase
  require "#{File.join(File.expand_path(File.dirname(__FILE__)), '../lib/frivol/time_extensions')}"

  def test_time
    time = Time.local(2014, 3, 4, 17, 53, 29)

    t = TestClass.new
    t.store(:time => time)

    t = TestClass.new
    assert_equal time, t.retrieve(:time => nil)
  end
end