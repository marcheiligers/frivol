# == Time
# An extension to the Time class which allows Time instances to be serialized by <tt>#to_json</tt> and deserialized by <tt>JSON#parse</tt>.
class Time
  # Serialize to JSON
  def to_json(*a)
    {
      'json_class'   => self.class.name,
      'data'         => self.to_s
    }.to_json(*a)
  end

  # Deserialize from JSON
  def self.json_create(o)
    Time.parse(*o['data'])
  end
end
