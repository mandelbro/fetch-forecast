# app/models/cached_forecast.rb
require 'rails_helper'

RSpec.describe CachedForecast, type: :model do
  it "validates the zip code" do
    cached_forecast_valid = create(:cached_forecast, zip_code: "12345")
    expect(cached_forecast_valid).to be_valid
  end

  it "validates the zip code length" do
    cached_forecast_invalid = build(:cached_forecast, zip_code: "123456")
    expect(cached_forecast_invalid).to be_invalid
    expect(cached_forecast_invalid.errors.full_messages).to include("Zip code must be 5 digits")
  end

  it "validates the zip code uniqueness" do
    create(:cached_forecast, zip_code: "12345")  # persist the conflict target
    cached_forecast_duplicate = build(:cached_forecast, zip_code: "12345")
    expect(cached_forecast_duplicate).to be_invalid
    expect(cached_forecast_duplicate.errors.full_messages).to include("Zip code has already been taken")
  end

  it "validates the forecast data" do
    expect(build(:cached_forecast)).to be_valid

    cached_forecast_invalid = build(:cached_forecast, forecast_data: nil)
    expect(cached_forecast_invalid).to be_invalid
    expect(cached_forecast_invalid.errors.full_messages).to include("Forecast data can't be blank")
  end

  it "validates the expires at" do
    cached_forecast = build(:cached_forecast, expires_at: 30.minutes.from_now)
    expect(build(:cached_forecast)).to be_valid
  end

  it "validates the expires at presence" do
    cached_forecast_no_expires_at = build(:cached_forecast, expires_at: nil)
    expect(cached_forecast_no_expires_at).to be_invalid
    expect(cached_forecast_no_expires_at.errors.full_messages).to include("Expires at time is required")
  end

  it "validates that expires at time is in the future" do
    cached_forecast_past_expires_at = build(:cached_forecast, expires_at: 5.minutes.ago)
    expect(cached_forecast_past_expires_at).to be_invalid
    expect(cached_forecast_past_expires_at.errors.full_messages).to include("Expires at must be in the future")
  end

  it "returns fresh forecasts" do
    fresh_forecast = create(:cached_forecast)
    expect(described_class.fresh).to include(fresh_forecast)

    stale_forecast = create(:cached_forecast, :stale)
    expect(described_class.fresh).not_to include(stale_forecast)
  end

  it "returns stale forecasts" do
    fresh_forecast = create(:cached_forecast)
    expect(described_class.stale).not_to include(fresh_forecast)

    stale_forecast = create(:cached_forecast, :stale)
    expect(described_class.stale).to include(stale_forecast)
  end

  it "returns forecasts for a given zip code" do
    forecast_1 = create(:cached_forecast, zip_code: "12345")
    forecast_2 = create(:cached_forecast, zip_code: "67890")
    expect(described_class.for_zip("12345")).to include(forecast_1)
    expect(described_class.for_zip("12345")).not_to include(forecast_2)
  end

  it "returns no forecasts for a non-existent zip code" do
    expect(described_class.for_zip("12345")).to be_empty
  end

  it "returns true if the forecast is fresh" do
    fresh_forecast = create(:cached_forecast)
    expect(fresh_forecast).to be_fresh

    stale_forecast = create(:cached_forecast, :stale)
    expect(stale_forecast).not_to be_fresh
  end

  it "returns true if the forecast is stale" do
    fresh_forecast = create(:cached_forecast)
    expect(fresh_forecast).not_to be_stale

    stale_forecast = create(:cached_forecast, :stale)
    expect(stale_forecast).to be_stale
  end

  it "returns the age in seconds" do
    fresh_forecast = create(:cached_forecast)
    expect(fresh_forecast.age_seconds).to be_zero

    stale_forecast = create(:cached_forecast, :stale)
    expect(stale_forecast.age_seconds).to be > 0
  end
end
