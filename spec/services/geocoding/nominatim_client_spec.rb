# spec/services/geocoding/nominatim_client_spec.rb
require 'rails_helper'

RSpec.describe Geocoding::NominatimClient do
  let(:client) { described_class.new }
  let(:success_response) { load_fixture("nominatim_success") }
  let(:empty_response) { load_fixture("nominatim_empty") }

  describe "#search" do
    let(:address) { "1 Apple Park Way, Cupertino, CA 95014, USA" }
    let(:url) { "https://nominatim.openstreetmap.org/search" }
    let(:request_headers) { { "User-Agent" => ENV.fetch("NOMINATIM_USER_AGENT") } }
    let(:response_headers) { { "Content-Type" => "application/json" } }
    let(:params) do
      {
        q: address,
        format: "json",
        limit: 1,
        addressdetails: 1,
        countrycodes: "us",
      }
    end

    it "returns the first result as a hash with the Nominatim response fields" do
      stub_request(:get, url)
        .with(query: params, headers: request_headers)
        .to_return(status: 200, body: success_response, headers: response_headers)

      result = client.search(address)
      expect(result).to be_a(Hash)
      expect(result).to include("place_id", "lat", "lon", "display_name", "address")
      expect(result["place_id"]).to eq(298110971)
    end

    it "raises a NotFoundError if no results are found" do
      stub_request(:get, url)
        .with(query: params, headers: request_headers)
        .to_return(status: 200, body: empty_response, headers: response_headers)

      expect { client.search(address) }.to raise_error(Geocoding::NominatimClient::NotFoundError)
    end

    it "raises a RateLimitError if the API returns a 429 response" do
      stub_request(:get, url)
        .with(query: params, headers: request_headers)
        .to_return(status: 429, body: "Too Many Requests")

      expect { client.search(address) }.to raise_error(Geocoding::NominatimClient::RateLimitError)
    end

    it "succeeds after 1 error" do
      # Return 500 response 1 time, then 200 response
      stub_request(:get, url)
        .with(query: params, headers: request_headers)
        .to_return(
        { status: 500, body: "Internal Server Error" },
        { status: 200, body: success_response, headers: response_headers })

      expect { client.search(address) }.not_to raise_error
      expect(WebMock).to have_requested(:get, url).with(query: params, headers: request_headers).twice
    end

    it "raises a ServiceError if the API returns a 500 response" do
      stub_request(:get, url)
        .with(query: params, headers: request_headers)
        .to_return(status: 500, body: "Internal Server Error")

      expect { client.search(address) }.to raise_error(Geocoding::NominatimClient::ServiceError)
    end
  end
end
