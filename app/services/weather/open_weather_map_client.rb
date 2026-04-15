# app/services/weather/open_weather_map_client.rb
# Thin HTTP wrapper around OpenWeatherMap API
# Weather::OpenWeatherMapClient

# Public interface:
# OpenWeatherMapClient.new        → client instance
# client.current_weather(zip)     → Hash with OWM current weather response fields
# client.forecast(zip)            → Hash with OWM 5-day/3-hour forecast response fields

# Endpoints:
# - GET /data/2.5/weather?zip={zip},US&appid={key}&units=imperial — current weather
# - GET /data/2.5/forecast?zip={zip},US&appid={key}&units=imperial — 5-day/3-hour forecast

# Raises
# OpenWeatherMapClient::Error for any error
# OpenWeatherMapClient::NotFoundError if 404, zip does not exist in OWM data
# OpenWeatherMapClient::UnauthorizedError if 401, invalid API key
# OpenWeatherMapClient::RateLimitError if API returns 429 (Too Many Requests)
# OpenWeatherMapClient::ServiceError for other 4xx or 5xx errors
module Weather
  class OpenWeatherMapClient
    class Error < StandardError; end
    class NotFoundError < StandardError; end
    class UnauthorizedError < StandardError; end
    class RateLimitError < StandardError; end
    class ServiceError < StandardError; end

    BASE_URL = "https://api.openweathermap.org/data/2.5"

    def initialize
      # Retry up to 2 times with exponential backoff for timeout, connection failed, and server errors
      @connection = Faraday.new(url: BASE_URL) do |f|
        f.request :retry, max: 2, interval: 0.5, backoff_factor: 2,
                  exceptions: [
                    Faraday::TimeoutError,
                    Faraday::ConnectionFailed,
                    Faraday::ServerError ]
        f.response :json # Parse the response as JSON
        f.response :raise_error # Raise an error for 4xx and 5xx responses
        f.adapter Faraday.default_adapter
      end
    end

    def current_weather(zip)
      response = get("weather", { zip: "#{zip},US" })
      response.body

    rescue Faraday::ResourceNotFound => e
      raise NotFoundError, "Could not find current weather data for zip: #{zip}"
    end

    def forecast(zip)
      response = get("forecast", { zip: "#{zip},US" })
      response.body

    rescue Faraday::ResourceNotFound => e
      raise NotFoundError, "Could not find forecast data for zip: #{zip}"
    end

    private

    def get(path, params)
      @connection.get(path, params.merge(appid: api_key, units: "imperial"))
    rescue Faraday::ServerError => e
      raise ServiceError, "OpenWeatherMap server error (#{path}): #{e.message}"
    rescue Faraday::TooManyRequestsError
      raise RateLimitError, "OpenWeatherMap rate limit exceeded (#{path})"
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed
      raise ServiceError, "OpenWeatherMap timeout or connection failed (#{path})"
    rescue Faraday::UnauthorizedError
      raise UnauthorizedError, "OpenWeatherMap authentication failed, check OPENWEATHERMAP_API_KEY in .env"
    end

    def api_key
      ENV.fetch("OPENWEATHERMAP_API_KEY")
    end
  end
end
