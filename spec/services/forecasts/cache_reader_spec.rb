# spec/services/forecasts/cache_reader_spec.rb
# Wraps the CachedForecast AR model to provide a simple interface for reading and writing cached forecasts

# Public interface:
# CacheReader.new             → client instance
# client.read(zip)            → CachedForecast instance
# client.write(zip, forecast) → CachedForecast instance
require 'rails_helper'

RSpec.describe Forecasts::CacheReader, type: :service do
  let(:reader) { described_class.new }
  let(:zip) { "95014" }

  describe "#read" do
    it "returns the CachedForecast instance when a fresh entry exists" do
      forecast = create(:cached_forecast, zip_code: zip)
      expect(reader.read(zip).forecast_data).to eq(forecast.forecast_data)
    end

    it "returns nil when no entry exists" do
      expect(reader.read(zip)).to be_nil
    end

    it "returns nil for a requested zip even when fresh entries exist for other zips" do
      create(:cached_forecast, zip_code: "99999")
      expect(reader.read(zip)).to be_nil
    end

    it "returns nil when the entry exists but is stale" do
      # create a stale entry, skipping validation
      create(:cached_forecast, :stale, zip_code: zip)

      expect(reader.read(zip)).to be_nil
    end
  end

  describe "#write" do
    let(:forecast_data) { { "zip_code" => zip, "current" => { "temp" => 68.2 } } }
    let(:forecast) { create(:cached_forecast, zip_code: zip, forecast_data: forecast_data) }

    it "creates a new entry and returns the persisted row when none exists" do
      expect(reader.write(zip, forecast_data).forecast_data).to eq(forecast_data)
    end

    it "updates the existing entry's forecast_data and expires_at on conflict and returns the persisted row" do
      stale_forecast_data = { "zip_code" => zip, "current" => { "temp" => 80.0 } }
      # create the initial entry with stale data
      initial_forecast = reader.write(zip, stale_forecast_data)
      initial_expires_at = initial_forecast.expires_at
      updated_forecast = reader.write(zip, forecast_data)
      # check that the stale data is updated
      expect(updated_forecast.forecast_data).to eq(forecast_data)
      # check that the expires_at is greater than the initial expires_at
      expect(updated_forecast.expires_at).to be > initial_expires_at
    end

    it "preserves created_at on upsert conflict" do
      # create the initial entry
      initial_forecast = create(:cached_forecast, zip_code: zip, forecast_data: forecast_data)
      # Re-write the forecast for the same zip code
      persisted_forecast = reader.write(zip, forecast_data)
      expect(persisted_forecast.created_at).to eq(initial_forecast.created_at)
    end

    it "returns the same record when re-writing the same zip" do
      first_write  = reader.write(zip, forecast_data)
      second_write = reader.write(zip, forecast_data)

      expect(second_write.id).to eq(first_write.id)
      expect(CachedForecast.for_zip(zip).count).to eq(1)
    end
  end
end
