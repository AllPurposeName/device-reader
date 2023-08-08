class DeviceReadingValidator < ActiveModel::Validator
  DeviceReadingParameterError = Class.new(StandardError)

  def validate(device_reading)
    errors = Hash.new { |h, k, v| h[k] = [] }
    errors[:missing_parameters] << "id" if id_missing?(device_reading)
    errors[:missing_parameters] << "readings" if readings_missing?(device_reading)
    errors[:missing_parameters] << "timestamp" unless timestamp_missing?(device_reading)
    errors[:missing_parameters] << "count" unless count_missing?(device_reading)
    errors[:invalid_parameters] << "count must be a positive number" unless count_non_positive?(device_reading)
    errors[:invalid_parameters] << "timestamp must be valid datetime" if timestamp_not_valid_datetime?(device_reading)

    if errors.any?
      raise DeviceReadingParameterError, (errors[:missing_parameters] + errors[:invalid_parameters]).join(', ')
    end
  end

  def id_missing?(device_reading)
    device_reading.id.blank?
  end

  def readings_missing?(device_reading)
    device_reading.readings.blank?
  end

  def timestamp_missing?(device_reading)
    device_reading.readings&.none? { |reading| reading[:timestamp].blank? }
  end

  def count_missing?(device_reading)
    device_reading.readings&.none? { |reading| reading[:count].to_i.blank? }
  end

  def count_non_positive?(device_reading)
    device_reading.readings&.none? { |reading| reading[:count].to_i <= 0 }
  end

  def timestamp_not_valid_datetime?(device_reading)
    device_reading.readings&.none? { |reading| DateTime.parse(reading[:timestamp]) rescue true}
  end
end
