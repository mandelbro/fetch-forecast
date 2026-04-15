# app/values/forecast.rb
require 'rails_helper'

RSpec.describe Forecast, type: :value do
  let(:fetched_at) { "2026-04-15T12:00:00Z" }
  let(:base_hash) do
    {
      "current_temp" => 68.2,
      "feels_like" => 66.4,
      "high" => 72.5,
      "low" => 54.1,
      "conditions" => "Clear",
      "zip_code" => "12345",
      "location_name" => "Cupertino",
      "country_code" => "US",
      "fetched_at" => fetched_at
    }
  end

  # .from_hash method
  describe ".from_hash" do
    it "builds a Forecast from a hash with string keys" do
      forecast = described_class.from_hash(base_hash)

      expect(forecast.current_temp).to eq(68.2)
    end

    it "parses fetched_at from an ISO8601 string back to time" do
      forecast = described_class.from_hash(base_hash)
      expect(forecast.fetched_at).to eq(Time.parse(fetched_at))
    end

    it "defaults extended to an empty array" do
      forecast = described_class.from_hash(base_hash)
      expect(forecast.extended).to eq([])
    end

    it "handles missing fetched_at as nil" do
      forecast = described_class.from_hash(base_hash.except("fetched_at"))
      expect(forecast.fetched_at).to be_nil
    end
  end

  describe "#to_h" do
    it "returns a hash with all fields" do
      hash = base_hash.merge("extended" => [])
      forecast = described_class.from_hash(hash)
      expect(forecast.to_h).to eq(hash)
    end

    it "serializes fetched_at as an ISO 8601 string" do
      forecast = described_class.from_hash(base_hash)
      expect(forecast.to_h["fetched_at"]).to eq(fetched_at)
    end

    it "returns nil for fetched_at when unset" do
      forecast = described_class.from_hash(base_hash.except("fetched_at"))
      expect(forecast.to_h["fetched_at"]).to be_nil
    end
  end

  describe "round-trip (from_hash -> to_h -> from_hash)" do
    it "preserves all fields" do
      forecast = described_class.from_hash(base_hash)
      expect(described_class.from_hash(forecast.to_h)).to eq(forecast)
    end

    it "preserves extended array" do
      hash_with_extended = base_hash.merge("extended" => [
        { "date" => "2026-04-16", "high" => 71.8, "low" => 52.3, "conditions" => "Clouds" },
        { "date" => "2026-04-17", "high" => 70.0, "low" => 51.5, "conditions" => "Clear" }
      ])
      forecast = described_class.from_hash(hash_with_extended)
      expect(described_class.from_hash(forecast.to_h)).to eq(forecast)
    end
  end

  describe "immutability" do
    it "is frozen after construction" do
      forecast = described_class.from_hash(base_hash)
      expect(forecast).to be_frozen
    end

    it "has a frozen extended array" do
      forecast = described_class.from_hash(base_hash)
      expect(forecast.extended).to be_frozen
    end
  end
end
