require "rails_helper"

RSpec.describe Forecasts::GetForecast do
  let(:address_resolver) { instance_double(Geocoding::AddressResolver) }
  let(:cache_reader) { instance_double(Forecasts::CacheReader) }
  let(:forecast_fetcher) { instance_double(Weather::ForecastFetcher) }

  let(:orchestrator) do
    described_class.new(
      address_resolver: address_resolver,
      cache_reader: cache_reader,
      forecast_fetcher: forecast_fetcher
    )
  end

  let(:raw_address) { "1 Apple Park Way, Cupertino, CA" }
  let(:zip) { "95014" }
  let(:fetched_at) { Time.zone.parse("2026-04-15 12:00:00") }
  let(:forecast) { Forecast.new(zip_code: zip, fetched_at: fetched_at) }
  let(:result) { orchestrator.call(raw_address) }

  describe "#call" do
    before do
      allow(address_resolver).to receive(:call).with(raw_address).and_return(Result.success(zip))
    end

    context "with a valid address and cache hit" do
      let(:cached_record) do
        instance_double(
          CachedForecast,
          forecast_data: forecast.to_h,
          created_at: 1.minute.ago,
          age_seconds: 60
        )
      end

      before do
        allow(cache_reader).to receive(:read).with(zip).and_return(cached_record)
      end

      it "returns a cached response with the deserialized forecast" do
        expect(result).to be_success
        expect(result.value.keys).to match_array(%i[forecast cached fetched_at age_seconds])
        expect(result.value[:forecast]).to be_a(Forecast)
        expect(result.value[:forecast].zip_code).to eq(zip)
        expect(result.value[:cached]).to be true
        expect(result.value[:fetched_at]).to eq(cached_record.created_at)
        expect(result.value[:age_seconds]).to eq(60)
      end

      it "does not call the fetcher or write to cache" do
        expect(forecast_fetcher).not_to receive(:call)
        expect(cache_reader).not_to receive(:write)

        orchestrator.call(raw_address)
      end
    end

    context "with a valid address and cache miss" do
      before do
        allow(cache_reader).to receive(:read).with(zip).and_return(nil)
        allow(cache_reader).to receive(:write)
        allow(forecast_fetcher).to receive(:call).with(zip).and_return(Result.success(forecast))
      end

      it "returns a fresh response from the fetcher" do
        expect(result).to be_success
        expect(result.value.keys).to match_array(%i[forecast cached fetched_at age_seconds])
        expect(result.value[:forecast]).to be(forecast)
        expect(result.value[:cached]).to be false
        expect(result.value[:fetched_at]).to eq(fetched_at)
        expect(result.value[:age_seconds]).to eq(0)
      end

      it "writes the forecast to the cache" do
        expect(cache_reader).to receive(:write).with(zip, forecast.to_h)

        orchestrator.call(raw_address)
      end
    end

    context "when address resolution fails" do
      let(:resolution_failure) do
        Result.failure(
          ForecastError.new(code: :address_not_resolved, user_message: "We couldn't find that address.")
        )
      end

      before do
        allow(address_resolver).to receive(:call).with(raw_address).and_return(resolution_failure)
      end

      it "propagates the resolver's failure unchanged" do
        expect(result).to be_failure
        expect(result.error.code).to eq(:address_not_resolved)
      end

      it "does not touch downstream services" do
        expect(cache_reader).not_to receive(:read)
        expect(forecast_fetcher).not_to receive(:call)
        expect(cache_reader).not_to receive(:write)

        orchestrator.call(raw_address)
      end
    end

    context "when fetcher fails after a cache miss" do
      let(:fetch_failure) do
        Result.failure(
          ForecastError.new(code: :weather_service_unavailable, user_message: "Service unavailable.")
        )
      end

      before do
        allow(cache_reader).to receive(:read).with(zip).and_return(nil)
        allow(forecast_fetcher).to receive(:call).with(zip).and_return(fetch_failure)
      end

      it "propagates the fetcher's failure unchanged" do
        expect(result).to be_failure
        expect(result.error.code).to eq(:weather_service_unavailable)
      end

      it "does not write to cache" do
        expect(cache_reader).not_to receive(:write)

        orchestrator.call(raw_address)
      end
    end
  end
end
