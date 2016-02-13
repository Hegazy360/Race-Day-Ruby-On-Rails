module RacersHelper

  def to_racer(value)
    return value.is_a?(Racer) ? value : Racer.new(value)
  end
end