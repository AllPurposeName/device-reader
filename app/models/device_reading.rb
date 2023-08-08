class DeviceReading
  include ActiveModel::Validations
  validates_with DeviceReadingValidator

  attr_reader :id, :readings
  def initialize(id:, readings:)
    @id = id
    @readings = readings
  end

  def self.create!(params:)
    device_record = new(id: params[:id], readings: params[:readings])
    device_record.valid?
    device_record
  end

  def hashed
    Digest::MD5.hexdigest({ id:, readings: }.to_s)
  end

  def cumulative_count
    readings.sum(0) { |reading| reading[:count].to_i }
  end

  def timestamps
    Array(readings.map { |reading| reading[:timestamp] })
  end
end
