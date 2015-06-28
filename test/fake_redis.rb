FAKE_REDIS = true

class Redis
  def initialize(config)
    @storage = {}
    @expires = Hash.new(nil)
    @version = config[:version] || "2.2.0"
    @results = []
  end

  def get(key)
    result = expired?(key) ? nil : @storage[key]
    @results << result
    result
  end

  def set(key, value)
    @storage[key] = value
    @expires.delete key
    @results << 'OK'
  end

  def info(key)
    { 'redis_version' => @version }
  end

  def del(key)
    @storage.delete key
    @expires.delete key
    @results << 1
    1
  end

  def incr(key)
    @storage[key] ||= 0
    result = @storage[key] += 1
    @results << result
    result
  end

  def incrby(key, amount)
    @storage[key] ||= 0
    result = @storage[key] += amount
    @results << result
    result
  end

  def decr(key)
    @storage[key] ||= 0
    result = @storage[key] -= 1
    @results << result
    result
  end

  def decrby(key, amount)
    @storage[key] ||= 0
    result = @storage[key] -= amount
    @results << result
    result
  end

  def expire(key, time)
    begin
      t = Integer(time)
    rescue
      raise RuntimeError.new("-ERR value is not an integer")
    end
    @expires[key] = Time.now + t
    @results << 1
    1
  end

  def exists(key)
    result = @storage.key?(key) && !expired?(key)
    @results << result
    result
  end

  def ttl(key)
    result = if expired?(key)
      -2
    elsif @expires[key].nil?
      -1
    else
      (@expires[key] - Time.now).to_i
    end
    @results << result
    result
  end

  def multi(&block)
    @results = []
    yield(self)
    @results
  end

  def flushdb
    @storage = {}
    @results << 'OK'
    'OK'
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

private
  def expired?(key)
    !@expires[key].nil? && @expires[key] < Time.now
  end
end
