class Redis
  def initialize(config)
    @storage = {}
  end

  def [](key)
    @storage[key]
  end

  def []=(key, value)
    @storage[key] = value
  end

  def expire(key, time)
    # Hmm, let's not do anything here
  end
end