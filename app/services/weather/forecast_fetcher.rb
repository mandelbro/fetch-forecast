# Given a zip code, fetch current conditions + 5-day forecast from OWM,
# aggregate into a single Forecast value object.
#
# Dependencies:
# - Weather::OpenWeatherMapClient (injectable for testing)
#
# Public interface:
# Weather::ForecastFetcher.new               → fetcher instance
# fetcher.call(zip)                          → Result<Forecast>
#
# Failure codes (on Result.error.code):
# - :invalid_zip_code              → OWM returned 404 (zip doesn't exist)
# - :weather_service_unavailable   → OWM auth/rate-limit/service error
module Weather
  class ForecastFetcher
    def initialize(client: Weather::OpenWeatherMapClient.new)
      @client = client
    end

    def call(zip)
      current  = @client.current_weather(zip)
      forecast = @client.forecast(zip)

      Result.success(build_forecast(zip, current, forecast))
    rescue Weather::OpenWeatherMapClient::NotFoundError => e
      Result.failure(invalid_zip_error(log_detail: e.message))
    rescue Weather::OpenWeatherMapClient::UnauthorizedError,
           Weather::OpenWeatherMapClient::RateLimitError,
           Weather::OpenWeatherMapClient::ServiceError => e
      Result.failure(service_unavailable_error(log_detail: e.message))
    end

    private

    def build_forecast(zip, current, forecast)
      daily = aggregate_daily(forecast["list"])
      today = daily.first

      Forecast.new(
        current_temp:  current.dig("main", "temp"),
        feels_like:    current.dig("main", "feels_like"),
        high:          today&.dig("high") || current.dig("main", "temp_max"),
        low:           today&.dig("low")  || current.dig("main", "temp_min"),
        conditions:    current.dig("weather", 0, "main"),
        extended:      daily,
        zip_code:      zip,
        location_name: current["name"],
        country_code:  current.dig("sys", "country"),
        fetched_at:    Time.current
      )
    end

    def aggregate_daily(buckets)
      buckets
        .group_by { |b| Date.parse(b["dt_txt"]).iso8601 }
        .map do |date, day_buckets|
          {
            "date"       => date,
            "high"       => day_buckets.map { |b| b.dig("main", "temp_max") }.max,
            "low"        => day_buckets.map { |b| b.dig("main", "temp_min") }.min,
            "conditions" => most_common_condition(day_buckets)
          }
        end
    end

    def most_common_condition(buckets)
      buckets
        .map { |b| b.dig("weather", 0, "main") }
        .tally
        .max_by { |_condition, count| count }
        &.first
    end

    def invalid_zip_error(log_detail:)
      ForecastError.new(
        code: :invalid_zip_code,
        user_message: "We couldn't find weather data for that ZIP code.",
        log_detail: log_detail
      )
    end

    def service_unavailable_error(log_detail:)
      ForecastError.new(
        code: :weather_service_unavailable,
        user_message: "Our weather service is temporarily unavailable. Please try again shortly.",
        log_detail: log_detail
      )
    end
  end
end
