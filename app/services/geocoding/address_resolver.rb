# Convert a user-entered address string → zip code string. Handles failure modes (Nominatim errors,
# missing postcode, etc.) and translates them to ForecastError.

# Public interface

# resolver = Geocoding::AddressResolver.new
# result = resolver.call(address_string)  # → Result<String>  (zip)
#                                           # or Result.failure(ForecastError)
module Geocoding
  class AddressResolver
    def initialize(client: Geocoding::NominatimClient.new)
      @client = client
    end

    def call(address)
      return Result.failure(invalid_input_error) if address.blank?

      response = @client.search(address)
      zip = response.dig("address", "postcode")

      if zip.blank? || !zip.match?(/\A\d{5}\z/)
        return Result.failure(address_not_resolved_error)
      end

      Result.success(zip)

    rescue Geocoding::NominatimClient::NotFoundError => e
      Result.failure(address_not_resolved_error(log_detail: e.message))
    rescue Geocoding::NominatimClient::RateLimitError,
           Geocoding::NominatimClient::ServiceError => e
      Result.failure(geocoding_service_unavailable_error(log_detail: e.message))
    end

    private

    def invalid_input_error
      ForecastError.new(
        code: :address_not_resolved,
        user_message: "Please enter an address."
      )
    end

    def address_not_resolved_error(log_detail: nil)
      ForecastError.new(
        code: :address_not_resolved,
        user_message: "We couldn't find that address. Try adding more detail (city, state, or ZIP).",
        log_detail: log_detail
      )
    end

    def geocoding_service_unavailable_error(log_detail: nil)
      ForecastError.new(
        code: :geocoding_service_unavailable,
        user_message: "Our address lookup service is temporarily unavailable. Please try again.",
        log_detail: log_detail
      )
    end
  end
end
