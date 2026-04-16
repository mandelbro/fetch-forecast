# Orchestrates the full forecast flow: address resolution → cache lookup → API fetch → cache write.
# Composes AddressResolver, CacheReader, and ForecastFetcher.
#
# Dependencies (all injectable for testing):
# - Geocoding::AddressResolver
# - Forecasts::CacheReader
# - Weather::ForecastFetcher
#
# Public interface:
# Forecasts::GetForecast.new     → orchestrator instance
# orchestrator.call(raw_address) → Result<Hash>
#
# Success value Hash keys:
# - forecast:    Forecast value object
# - cached:      Boolean (true = cache hit, false = fresh from API)
# - fetched_at:  Time the forecast was originally fetched
# - age_seconds: Integer seconds since the forecast was fetched
#
# Failure codes (propagated unchanged from collaborators):
# - :address_not_resolved          → from AddressResolver
# - :geocoding_service_unavailable → from AddressResolver
# - :invalid_zip_code              → from ForecastFetcher
# - :weather_service_unavailable   → from ForecastFetcher
module Forecasts
  class GetForecast
    def initialize(
      address_resolver: Geocoding::AddressResolver.new,
      cache_reader: Forecasts::CacheReader.new,
      forecast_fetcher: Weather::ForecastFetcher.new
    )
      @address_resolver = address_resolver
      @cache_reader = cache_reader
      @forecast_fetcher = forecast_fetcher
    end

    def call(raw_address)
      resolution = @address_resolver.call(raw_address)
      return resolution unless resolution.success?
      zip = resolution.value

      cached_record = @cache_reader.read(zip)
      return cached_response(cached_record) if cached_record

      fetch_result = @forecast_fetcher.call(zip)
      return fetch_result unless fetch_result.success?
      forecast = fetch_result.value

      @cache_reader.write(zip, forecast.to_h)
      fresh_response(forecast)
    end

    private

    def cached_response(cached_record)
      Result.success({
        forecast: Forecast.from_hash(cached_record.forecast_data),
        cached: true,
        fetched_at: cached_record.created_at,
        age_seconds: cached_record.age_seconds
      })
    end

    def fresh_response(forecast)
      Result.success({
        forecast: forecast,
        cached: false,
        fetched_at: forecast.fetched_at,
        age_seconds: 0
      })
    end
  end
end
