# app/services/geocoding/nominatim_client.rb
# Thin HTTP wrapper around Nominatim API
# Geocoding::NominatimClient

# Public interface:
# NominatimClient.new             → client instance
# client.search(address_string)   → Hash with Nominatim response fields

# Endpoints:
# - GET /search?q={address}&format=json — search for addresses

# Raises
# NominatimClient::NotFoundError if API returns no results
# NominatimClient::RateLimitError if API returns 429 (Too Many Requests)
# NominatimClient::ServiceError for other 4xx or 5xx errors
module Geocoding
  class NominatimClient
    class NotFoundError < StandardError; end
    class RateLimitError < StandardError; end
    class ServiceError < StandardError; end

    BASE_URL = "https://nominatim.openstreetmap.org"

    def initialize
      # Retry up to 2 times with exponential backoff for timeout, connection failed, and server errors
      @connection = Faraday.new(url: BASE_URL) do |f|
        f.headers["User-Agent"] = ENV.fetch("NOMINATIM_USER_AGENT")
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

    def search(address)
      response = @connection.get("/search", { q: address, format: "json" })
      result = response.body.first
      if result.blank?
        raise NotFoundError, "No results found for address: #{address}"
      end

      result
    rescue Faraday::ServerError => e
      raise ServiceError, "Server error: #{e.message}"
    rescue Faraday::TooManyRequestsError
      raise RateLimitError, "Rate limit exceeded"
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed
      raise ServiceError, "Timeout or connection failed"
    end
  end
end
