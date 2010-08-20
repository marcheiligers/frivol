class Redis
  def initialize(config)
    @storage = {}
  end

  def [](key)
    # puts "retrieve #{key}"
    @storage[key]
  end

  def []=(key, value)
    # puts "store #{key}"
    @storage[key] = value
  end

  def expire(key, time)
    # Hmm, let's not do anything here
    # puts "expiring #{key} in #{time}"
  end
end