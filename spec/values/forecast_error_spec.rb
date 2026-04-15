# app/values/forecast_error.rb
require 'rails_helper'

RSpec.describe ForecastError, type: :value do
  it "creates an error with code, user_message, and log_detail" do
    error = described_class.new(
              code: :weather_service_unavailable,
              user_message: "Weather service unavailable",
              log_detail: "Weather service returned 500 Internal Server Error")

    expect(error.code).to eq(:weather_service_unavailable)
    expect(error.user_message).to eq("Weather service unavailable")
    expect(error.log_detail).to eq("Weather service returned 500 Internal Server Error")
  end

  it "treats log_detail as optional" do
    error = described_class.new(
              code: :weather_service_unavailable,
              user_message: "Weather service unavailable")

    expect(error.log_detail).to be_nil
  end

  it "raises ArgumentError when constructed with unknown code" do
    expect do
      described_class.new(code: :unknown_code, user_message: "Unknown code")
    end.to raise_error(ArgumentError)
  end

  it "surfaces the valid codes in the error message" do
    expect do
      described_class.new(code: :unknown_code, user_message: "Unknown code")
    end.to raise_error(
      ArgumentError,
      include("Valid codes are: #{ForecastError::ERROR_CODES.to_a.join(', ')}")
    )
  end

  it "raises ArgumentError when user message is nil" do
    expect do
      described_class.new(code: :weather_service_unavailable, user_message: nil)
    end.to raise_error(ArgumentError)
  end

  it "raises ArgumentError when user message is blank" do
    expect do
      described_class.new(code: :weather_service_unavailable, user_message: "")
    end.to raise_error(ArgumentError)
  end

  it "accepts all documented code from the CODES set" do
    # check that the number of codes is correct
    expect(ForecastError::ERROR_CODES.size).to eq(5)

    ForecastError::ERROR_CODES.each do |code|
      expect { described_class.new(code: code, user_message: "User message for #{code}") }.not_to raise_error
    end
  end

  # it is frozen (immutable)
  it "is frozen (immutable)" do
    error = described_class.new(
              code: :weather_service_unavailable,
              user_message: "Weather service unavailable",
              log_detail: "Weather service returned 500 Internal Server Error")

    expect(error).to be_frozen
  end
end
