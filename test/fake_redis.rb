FAKE_REDIS = true

class Redis
  def initialize(config)
    @storage = {}
    @expires = Hash.new(nil)
    @version = config[:version] || "2.2.0"
  end

  def [](key)
    # puts "retrieve #{key} => #{@storage[key]} (#{(!@expires[key].nil? && @expires[key] < Time.now) ? 'expired' : 'alive'})"
    return nil if !@expires[key].nil? && @expires[key] < Time.now
    @storage[key]
  end

  def []=(key, value)
    # puts "store #{key} => #{value}"
    @storage[key] = value
    @expires.delete key
  end

  def info(key)
    { 'redis_version' => @version }
  end

  def del(key)
    # puts "del #{key}"
    @storage.delete key
    @expires.delete key
  end

  def incr(key)
    # puts "incr #{key}"
    @storage[key] ||= 0
    @storage[key] += 1
  end

  def incrby(key, amount)
    # puts "incr #{key}"
    @storage[key] ||= 0
    @storage[key] += amount
  end

  def decr(key)
    # puts "decr #{key}"
    @storage[key] ||= 0
    @storage[key] -= 1
  end

  def decrby(key, amount)
    # puts "decr #{key}"
    @storage[key] ||= 0
    @storage[key] -= amount
  end

  def expire(key, time)
    begin
      t = Integer(time)
    rescue
      raise RuntimeError.new("-ERR value is not an integer")
    end
    @expires[key] = Time.now + t
  end

  def exists(key)
    @storage.key? key
  end

  def ttl(key)
    # puts "ttl #{key}"
    return -1 if @expires[key].nil? || @expires[key] < Time.now
    (@expires[key] - Time.now).to_i
  end

  def multi(&block)
    yield(self)
  end

  def flushdb
    @storage = {}
  end

  # Help with debugging
  def inspect
    @storage.keys.sort.map do |key|
      result = "\n#{key} => #{@storage[key].inspect}"
      result << "\n\texpires at #{@expires[key]}" if @expires.key?(key)
      result
    end
  end

  def method_missing(meth, *args, &block)
    puts "Missing method: #{meth} called with #{args.inspect}"
  end
end
