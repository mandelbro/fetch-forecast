# spec/services/weather/open_weather_map_client_spec.rb
require 'rails_helper'

RSpec.describe Weather::OpenWeatherMapClient do
  let(:api_key) { ENV.fetch("OPENWEATHERMAP_API_KEY") }
  let(:client) { described_class.new }
  let(:response_headers) { { "Content-Type" => "application/json" } }
  let(:zip) { "95014" }
  let(:zip_param) { "#{zip},US" }

  describe "#current_weather" do
    let(:current_weather_url) { "https://api.openweathermap.org/data/2.5/weather" }
    let(:current_weather_params) { { zip: zip_param, appid: api_key, units: "imperial" } }
    let(:success_current_weather_response) { load_fixture("openweathermap_current") }

    it "returns the parsed response for a valid zip" do
      stub_request(:get, current_weather_url)
        .with(query: current_weather_params)
        .to_return(status: 200, body: success_current_weather_response, headers: response_headers)

      result = client.current_weather(zip)
      expect(result).to be_a(Hash)
      expect(result).to include("coord", "weather", "main", "name", "clouds", "dt", "sys", "timezone", "id", "cod", "base")
      expect(result["main"]["temp"]).to eq(65.52)
    end

    it "raises a NotFoundError if the zip does not exist" do
      stub_request(:get, current_weather_url)
        .with(query: current_weather_params)
        .to_return(status: 404, body: "Not Found")

      expect { client.current_weather(zip) }.to raise_error(Weather::OpenWeatherMapClient::NotFoundError)
    end

    it "raises a UnauthorizedError if the API key is invalid" do
      stub_request(:get, current_weather_url)
        .with(query: current_weather_params)
        .to_return(status: 401, body: "Unauthorized")

      expect { client.current_weather(zip) }.to raise_error(Weather::OpenWeatherMapClient::UnauthorizedError)
    end

    it "raises a RateLimitError if the API returns 429 (Too Many Requests)" do
      stub_request(:get, current_weather_url)
        .with(query: current_weather_params)
        .to_return(status: 429, body: "Too Many Requests")

      expect { client.current_weather(zip) }.to raise_error(Weather::OpenWeatherMapClient::RateLimitError)
    end

    it "succeeds after 1 retry on transient errors" do
      stub_request(:get, current_weather_url)
        .with(query: current_weather_params)
        .to_return(
          { status: 500, body: "Internal Server Error" },
          { status: 200, body: success_current_weather_response, headers: response_headers })

      expect { client.current_weather(zip) }.not_to raise_error
      expect(WebMock).to have_requested(:get, current_weather_url)
        .with(query: current_weather_params).twice
    end

    it "raises a ServiceError if the API returns a 500 response after 3 attempts" do
      stub_request(:get, current_weather_url)
        .with(query: current_weather_params)
        .to_return(status: 500, body: "Internal Server Error").times(3)

      expect { client.current_weather(zip) }.to raise_error(Weather::OpenWeatherMapClient::ServiceError)
    end
  end

  describe "#forecast" do
    let(:forecast_url) { "https://api.openweathermap.org/data/2.5/forecast" }
    let(:forecast_params) { { zip: zip_param, appid: api_key, units: "imperial" } }
    let(:success_forecast_response) { load_fixture("openweathermap_forecast") }

    it "returns the parsed response for a valid zip" do
      stub_request(:get, forecast_url)
        .with(query: forecast_params)
        .to_return(status: 200, body: success_forecast_response, headers: response_headers)

      result = client.forecast(zip)
      expect(result).to be_a(Hash)
      expect(result).to include("cod", "city", "list")
      expect(result["list"].count).to eq(40)
    end
  end
end
