require "rails_helper"

RSpec.describe Geocoding::AddressResolver do
  let(:client) { instance_double(Geocoding::NominatimClient) }
  let(:resolver) { described_class.new(client: client) }

  describe "#call" do
    context "with a valid US address" do
      before do
        allow(client).to receive(:search)
          .with("1 Apple Park Way, Cupertino, CA")
          .and_return({ "address" => { "postcode" => "94087" } })
      end

      it "returns Result.success with the zip" do
        result = resolver.call("1 Apple Park Way, Cupertino, CA")

        expect(result).to be_success
        expect(result.value).to eq("94087")
      end
    end

    context "with a blank address" do
      it "returns Result.failure without calling the client" do
        result = resolver.call("")

        expect(result).to be_failure
        expect(result.error.code).to eq(:address_not_resolved)
        expect(result.error.user_message).to eq("Please enter an address.")
      end

      it "handles nil the same way" do
        result = resolver.call(nil)

        expect(result).to be_failure
        expect(result.error.code).to eq(:address_not_resolved)
        expect(result.error.user_message).to eq("Please enter an address.")
      end
    end

    context "when Nominatim returns a result without postcode" do
      before do
        allow(client).to receive(:search)
          .and_return({ "address" => { "city" => "Cupertino" } })
      end

      it "returns Result.failure with :address_not_resolved" do
        result = resolver.call("somewhere vague")

        expect(result).to be_failure
        expect(result.error.code).to eq(:address_not_resolved)
        expect(result.error.user_message).to include("couldn't find")
      end
    end

    context "when Nominatim returns a non-5-digit postcode" do
      before do
        allow(client).to receive(:search)
          .and_return({ "address" => { "postcode" => "9408" } })
      end

      it "returns Result.failure with :address_not_resolved" do
        result = resolver.call("partial address")

        expect(result).to be_failure
        expect(result.error.code).to eq(:address_not_resolved)
        expect(result.error.user_message).to include("couldn't find")
      end
    end

    context "when the client raises NotFoundError" do
      before do
        allow(client).to receive(:search)
          .and_raise(Geocoding::NominatimClient::NotFoundError, "No results found")
      end

      it "returns Result.failure with :address_not_resolved" do
        result = resolver.call("nonexistent place")

        expect(result).to be_failure
        expect(result.error.code).to eq(:address_not_resolved)
        expect(result.error.user_message).to include("couldn't find")
        expect(result.error.log_detail).to eq("No results found")
      end
    end

    context "when the client raises RateLimitError" do
      before do
        allow(client).to receive(:search)
          .and_raise(Geocoding::NominatimClient::RateLimitError, "Rate limit exceeded")
      end

      it "returns Result.failure with :geocoding_service_unavailable" do
        result = resolver.call("any address")

        expect(result).to be_failure
        expect(result.error.code).to eq(:geocoding_service_unavailable)
        expect(result.error.user_message).to include("temporarily unavailable")
        expect(result.error.log_detail).to eq("Rate limit exceeded")
      end
    end

    context "when the client raises ServiceError" do
      before do
        allow(client).to receive(:search)
          .and_raise(Geocoding::NominatimClient::ServiceError, "Timeout or connection failed")
      end

      it "returns Result.failure with :geocoding_service_unavailable" do
        result = resolver.call("any address")

        expect(result).to be_failure
        expect(result.error.code).to eq(:geocoding_service_unavailable)
        expect(result.error.user_message).to include("temporarily unavailable")
        expect(result.error.log_detail).to eq("Timeout or connection failed")
      end
    end
  end
end
