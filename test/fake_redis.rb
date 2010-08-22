class Redis
  def initialize(config)
    @storage = {}
    @expires = Hash.new(nil)
  end

  def [](key)
    # puts "retrieve #{key}"
    return nil if !@expires[key].nil? && @expires[key] < Time.now
    @storage[key]
  end

  def []=(key, value)
    # puts "store #{key}"
    @storage[key] = value
  end

  def del(key)
    # puts "del #{key}"
    @storage[key] = nil
    @expires[key] = nil
  end
  
  def expire(key, time)
    @expires[key] = Time.now + time
  end
  
  def flush_db
    @storage = {}
  end
end