require "rails_helper"

RSpec.describe Weather::ForecastFetcher do
  include ActiveSupport::Testing::TimeHelpers

  let(:client) { instance_double(Weather::OpenWeatherMapClient) }
  let(:fetcher) { described_class.new(client: client) }
  let(:zip) { "95014" }
  let(:current_response) { load_fixture_json("openweathermap_current") }
  let(:forecast_response) { load_fixture_json("openweathermap_forecast") }

  describe "#call" do
    context "with a valid zip" do
      before do
        allow(client).to receive(:current_weather).with(zip).and_return(current_response)
        allow(client).to receive(:forecast).with(zip).and_return(forecast_response)
      end

      it "returns Result.success with a Forecast" do
        result = fetcher.call(zip)

        expect(result).to be_success
        expect(result.value).to be_a(Forecast)
      end

      it "populates current-weather fields" do
        forecast = fetcher.call(zip).value

        expect(forecast.current_temp).to eq(65.52)
        expect(forecast.feels_like).to eq(64.26)
        expect(forecast.conditions).to eq("Clouds")
      end

      it "derives today's high/low from the forecast aggregation, not from current weather" do
        forecast = fetcher.call(zip).value

        expect(forecast.high).to eq(64.9)
        expect(forecast.low).to eq(63.7)
      end

      it "populates the location and country" do
        forecast = fetcher.call(zip).value

        expect(forecast.location_name).to eq("Cupertino")
        expect(forecast.country_code).to eq("US")
        expect(forecast.zip_code).to eq("95014")
      end

      it "sets fetched_at to the current time" do
        freeze_time = Time.zone.parse("2026-04-15 12:00:00")
        travel_to(freeze_time) do
          forecast = fetcher.call(zip).value
          expect(forecast.fetched_at).to eq(freeze_time)
        end
      end

      it "aggregates the extended forecast into daily entries" do
        forecast = fetcher.call(zip).value

        expect(forecast.extended).to be_an(Array)
        expect(forecast.extended.length).to eq(6)
        expect(forecast.extended.map { |d| d["date"] }).to eq(%w[
          2026-04-15 2026-04-16 2026-04-17 2026-04-18 2026-04-19 2026-04-20
        ])
      end

      it "returns high and low per day across the 3-hour buckets" do
        forecast = fetcher.call(zip).value

        april_16 = forecast.extended.find { |d| d["date"] == "2026-04-16" }
        expect(april_16["high"]).to eq(67.93)
        expect(april_16["low"]).to eq(43.29)

        april_17 = forecast.extended.find { |d| d["date"] == "2026-04-17" }
        expect(april_17["high"]).to eq(70.65)
        expect(april_17["low"]).to eq(48.06)
      end

      it "picks the most common weather condition per day" do
        forecast = fetcher.call(zip).value

        april_16 = forecast.extended.find { |d| d["date"] == "2026-04-16" }
        expect(april_16["conditions"]).to eq("Clouds")

        april_17 = forecast.extended.find { |d| d["date"] == "2026-04-17" }
        expect(april_17["conditions"]).to eq("Clear")
      end
    end

    context "when current_weather raises NotFoundError" do
      before do
        allow(client).to receive(:current_weather)
          .and_raise(Weather::OpenWeatherMapClient::NotFoundError, "zip not found")
      end

      it "returns Result.failure with :invalid_zip_code" do
        result = fetcher.call(zip)

        expect(result).to be_failure
        expect(result.error.code).to eq(:invalid_zip_code)
        expect(result.error.user_message).to include("couldn't find weather data")
        expect(result.error.log_detail).to eq("zip not found")
      end
    end

    shared_examples "translates client error to :weather_service_unavailable" do |error_class, error_msg|
      it "from current_weather" do
        allow(client).to receive(:current_weather).and_raise(error_class, error_msg)

        result = fetcher.call(zip)

        expect(result).to be_failure
        expect(result.error.code).to eq(:weather_service_unavailable)
        expect(result.error.user_message).to include("temporarily unavailable")
        expect(result.error.log_detail).to eq(error_msg)
      end

      it "from forecast" do
        allow(client).to receive(:current_weather).with(zip).and_return(current_response)
        allow(client).to receive(:forecast).and_raise(error_class, error_msg)

        result = fetcher.call(zip)

        expect(result).to be_failure
        expect(result.error.code).to eq(:weather_service_unavailable)
        expect(result.error.user_message).to include("temporarily unavailable")
        expect(result.error.log_detail).to eq(error_msg)
      end
    end

    it_behaves_like "translates client error to :weather_service_unavailable",
      Weather::OpenWeatherMapClient::UnauthorizedError, "bad API key"
    it_behaves_like "translates client error to :weather_service_unavailable",
      Weather::OpenWeatherMapClient::RateLimitError, "rate limited"
    it_behaves_like "translates client error to :weather_service_unavailable",
      Weather::OpenWeatherMapClient::ServiceError, "server error"
  end
end
