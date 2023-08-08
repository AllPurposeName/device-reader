class DeviceReadingController < ApplicationController
  def create
    DeviceReadingMemoryStorage.ingest!(params: create_params)
    render json: {}, status: 201
  rescue DeviceReadingValidator::DeviceReadingParameterError => e
    render json: { message: invalid_parameters(e.message) }, status: 422
  end

  def create_params
    params.permit(:id, readings: [:timestamp, :count]).to_h
  end

  def invalid_parameters(errors)
    "Missing or invalid parameters: #{errors}"
  end
end
