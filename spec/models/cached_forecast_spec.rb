require 'rails_helper'

RSpec.describe CachedForecast, type: :model do
  # add a test for the validations
  it "validates the zip code" do
    cached_forecast_valid = create(:cached_forecast, zip_code: "12345")
    expect(cached_forecast_valid).to be_valid

    cached_forecast_invalid = build(:cached_forecast, zip_code: "123456")
    expect(cached_forecast_invalid).to be_invalid
    expect(cached_forecast_invalid.errors.full_messages).to include("Zip code must be 5 digits")

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

    cached_forecast_no_expires_at = build(:cached_forecast, expires_at: nil)
    expect(cached_forecast_no_expires_at).to be_invalid
    expect(cached_forecast_no_expires_at.errors.full_messages).to include("Expires at time is required")

    cached_forecast_past_expires_at = build(:cached_forecast, expires_at: 5.minutes.ago)
    expect(cached_forecast_past_expires_at).to be_invalid
    expect(cached_forecast_past_expires_at.errors.full_messages).to include("Expires at must be in the future")
  end

  # add a test for the fresh scope
  it "returns fresh forecasts" do
    fresh_forecast = create(:cached_forecast)
    expect(CachedForecast.fresh).to include(fresh_forecast)

    stale_forecast = create(:cached_forecast, :stale)
    expect(CachedForecast.fresh).not_to include(stale_forecast)
  end

  # add a test for the stale scope
  it "returns stale forecasts" do
    fresh_forecast = create(:cached_forecast)
    expect(CachedForecast.stale).not_to include(fresh_forecast)

    stale_forecast = create(:cached_forecast, :stale)
    expect(CachedForecast.stale).to include(stale_forecast)
  end

  # add a test for the for_zip scope
  it "returns forecasts for a given zip code" do
    forecast_1 = create(:cached_forecast, zip_code: "12345")
    forecast_2 = create(:cached_forecast, zip_code: "67890")
    expect(CachedForecast.for_zip("12345")).to include(forecast_1)
    expect(CachedForecast.for_zip("12345")).not_to include(forecast_2)
  end

  # add a test for the for_zip scope with a non-existent zip code
  it "returns no forecasts for a non-existent zip code" do
    expect(CachedForecast.for_zip("12345")).to be_empty
  end

  # add a test for the fresh? predicate
  it "returns true if the forecast is fresh" do
    fresh_forecast = create(:cached_forecast)
    expect(fresh_forecast.fresh?).to be_truthy

    stale_forecast = create(:cached_forecast, :stale)
    expect(stale_forecast.fresh?).to be_falsey
  end

  # add a test for the stale? predicate
  it "returns true if the forecast is stale" do
    fresh_forecast = create(:cached_forecast)
    expect(fresh_forecast.stale?).to be_falsey

    stale_forecast = create(:cached_forecast, :stale)
    expect(stale_forecast.stale?).to be_truthy
  end

  # add a test for the age_seconds
  it "returns the age in seconds" do
    fresh_forecast = create(:cached_forecast)
    expect(fresh_forecast.age_seconds).to be_zero

    stale_forecast = create(:cached_forecast, :stale)
    expect(stale_forecast.age_seconds).to be > 0
  end
end
