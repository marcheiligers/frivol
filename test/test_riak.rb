require "#{File.expand_path(File.dirname(__FILE__))}/helper.rb"

class TestRiak < Test::Unit::TestCase
  if riak_test?
    def test_prefix
      backend = Frivol::Backend::Riak.new(
        :protocol => 'http',
        :nodes => [ { :host => '127.0.0.1' } ],
        :prefix => 'test_riak_'
      )
      Frivol::Config.backend = backend

      t = Class.new(TestClass) do
        storage_bucket :meat
        storage_bucket :and, :expires_in => 100
        storage_bucket :veg, :counter => true
      end.new

      t.store :test_key => 'test_value'
      nonprefixed_bucket = backend.connection.bucket("frivol_objects")
      refute nonprefixed_bucket.exist?(t.storage_key)
      prefixed_bucket = backend.connection.bucket("test_riak_frivol_objects")
      assert prefixed_bucket.exist?(t.storage_key)

      t.store_meat :test_key => 'test_value'
      refute nonprefixed_bucket.exist?(t.storage_key(:meat))
      assert prefixed_bucket.exist?(t.storage_key(:meat))

      t.store_and :test_key => 'test_value'
      nonprefixed_bucket = backend.connection.bucket("frivol_expires")
      refute nonprefixed_bucket.exist?(t.storage_key(:and))
      prefixed_bucket = backend.connection.bucket("test_riak_frivol_expires")
      assert prefixed_bucket.exist?(t.storage_key(:and))

      t.store_veg 5 # a day
      nonprefixed_bucket = backend.connection.bucket("frivol_counters")
      refute nonprefixed_bucket.exist?(t.storage_key(:veg))
      prefixed_bucket = backend.connection.bucket("test_riak_frivol_counters")
      assert prefixed_bucket.exist?(t.storage_key(:veg))
    end
  end
end