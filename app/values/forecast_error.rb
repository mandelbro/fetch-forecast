# app/values/forecast_error.rb
# Purpose: Structured error with machine-readable code, human-readable message, and log detail.
# Immutable struct with keyword_init: true.
#
# public interface:
# - code -> machine-readable code
# - user_message -> human-readable message
# - log_detail -> String or nil
class ForecastError
  ERROR_CODES = %i[
    address_not_resolved
    address_outside_service_area
    invalid_zip_code
    weather_service_unavailable
    geocoding_service_unavailable
  ].freeze

  attr_reader :code, :user_message, :log_detail

  def initialize(code:, user_message:, log_detail: nil)
    unless ERROR_CODES.include?(code)
      raise ArgumentError, "Invalid code: #{code}. Valid codes are: #{ERROR_CODES.join(', ')}"
    end
    raise ArgumentError, "User message is required" if user_message.blank?

    @code = code
    @user_message = user_message
    @log_detail = log_detail

    freeze
  end
end
