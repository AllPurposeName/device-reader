class DeviceReadingMemoryStorage
  def self.read(params:)
    new(device_reading: DeviceReading.build(params:)).to_h
  end

  def self.ingest!(params:)
    new(device_reading: DeviceReading.create!(params:)).ingest!
  end

  attr_reader :device_reading, :memory_store
  def initialize(device_reading:, memory_store: Rails.cache)
    @memory_store = memory_store
    @device_reading = device_reading
  end

  def to_h
    {
      cumulative_count:,
      latest_timestamp:,
    }
  end

  def cumulative_count
    memory_store.read("#{device_reading.id}/cumulative_count") || 0
  end

  def latest_timestamp
    memory_store.read("#{device_reading.id}/latest_timestamp") || ""
  end

  def ingest!
    return if already_ingested?
    create_ingestion
    remove_duplicates
    add_reading_to_device
    increment_count
    set_latest_timestamp
  end

  def already_ingested?
    memory_store.exist?(device_reading.hashed)
  end

  def create_ingestion
    memory_store.write(device_reading.hashed, true)
  end

  def remove_duplicates
    existing_readings = Array(memory_store.read(device_reading.id))
    duplicates = device_reading.readings & existing_readings

    duplicates.each do |duplicate|
      device_reading.readings.delete(duplicate)
    end
  end

  def increment_count
    if memory_store.exist?("#{device_reading.id}/cumulative_count")
      memory_store.increment("#{device_reading.id}/cumulative_count", device_reading.cumulative_count)
    else
      memory_store.write("#{device_reading.id}/cumulative_count", device_reading.cumulative_count)
    end
  end

  def add_reading_to_device
    existing_readings = Array(memory_store.read(device_reading.id))
    new_readings = device_reading.readings + existing_readings
    memory_store.write(device_reading.id, new_readings)
  end

  def set_latest_timestamp
    current_latest = Array(memory_store.read("#{device_reading.id}/latest_timestamp"))
    new_latest = (device_reading.timestamps + current_latest).max_by { |ts| DateTime.parse(ts) }
    return if current_latest == new_latest
    memory_store.write("#{device_reading.id}/latest_timestamp", new_latest)
  end
end
