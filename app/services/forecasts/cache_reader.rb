# app/services/forecasts/cache_reader.rb
# Wraps the CachedForecast AR model to provide a simple interface for reading and writing cached forecasts

# Public interface:
# CacheReader.new             → client instance
# client.read(zip)            → CachedForecast instance
# client.write(zip, forecast) → CachedForecast instance
module Forecasts
  class CacheReader
    TTL_MINUTES = 30

    def read(zip_code)
      CachedForecast.for_zip(zip_code).fresh.first
    end

    def write(zip_code, forecast_data)
      CachedForecast.upsert(
        {
          zip_code: zip_code,
          forecast_data: forecast_data,
          expires_at: TTL_MINUTES.minutes.from_now
        },
        unique_by: :zip_code,
        update_only: [:forecast_data, :expires_at]
      )

      # Return the persisted row for the caller
      CachedForecast.for_zip(zip_code).first
    end
  end
end
