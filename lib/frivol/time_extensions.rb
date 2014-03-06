require 'time'

# == Time
# An extension to the <tt>Time</tt> class which allows instances to be
# serialized by <tt>MultiJson#dump</tt> and deserialized by
# <tt>MultiJson#load</tt>.
class Time
  # Rails support
  def as_json(*a)
    {
      'json_class'   => self.class.name,
      'data'         => self.to_s
    }
  end

  # Serialize to JSON
  def to_json(*a)
    MultiJson.dump(as_json(*a))
  end

  # Deserialize from JSON
  def self.json_create(o)
    Time.parse(*o['data'])
  end
end

Frivol::Config.allow_json_create << Time

begin
  # == ActiveSupport::TimeWithZone
  # An extension to the <tt>ActiveSupport::TimeWithZone</tt> class which allows
  # instances to be serialized by <tt>MultiJson#dump</tt> and deserialized by
  # <tt>MultiJson#load</tt>.
  class ActiveSupport::TimeWithZone
    # Rails support
    def as_json(*a)
      {
        'json_class'   => self.class.name,
        'data'         => self.to_s
      }
    end

    # Serialize to JSON
    def to_json(*a)
      MultiJson.dump(as_json(*a))
    end

    # Deserialize from JSON
    def self.json_create(o)
      Time.zone.parse(*o['data'])
    end
  end

  Frivol::Config.allow_json_create << ActiveSupport::TimeWithZone
rescue; end