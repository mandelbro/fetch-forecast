require "rails_helper"

RSpec.describe "Forecasts", type: :request do
  describe "GET /" do
    it "renders the forecast form" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Fetch Forecast")
      expect(response.body).to include("address")
    end
  end

  describe "GET /forecast" do
    let(:address) { "1 Apple Park Way, Cupertino, CA 95014" }

    context "with a blank address param" do
      it "redirects to root" do
        get forecast_path

        expect(response).to redirect_to(root_path)
      end

      it "handles whitespace-only params" do
        get forecast_path, params: { address: "   " }

        expect(response).to redirect_to(root_path)
      end
    end

    context "with a valid address (cache miss)" do
      let(:forecast) do
        Forecast.new(
          zip_code: "95014",
          current_temp: 65.5,
          feels_like: 63.0,
          high: 72.0,
          low: 52.0,
          conditions: "Clear",
          extended: [],
          location_name: "Cupertino",
          country_code: "US",
          fetched_at: Time.current
        )
      end

      let(:success_result) do
        Result.success({
          forecast: forecast,
          cached: false,
          fetched_at: Time.current,
          age_seconds: 0
        })
      end

      before do
        allow_any_instance_of(Forecasts::GetForecast)
          .to receive(:call).with(address).and_return(success_result)
      end

      it "renders the forecast view with location details" do
        get forecast_path, params: { address: address }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Cupertino")
        expect(response.body).to include("95014")
      end
    end

    {
      address_not_resolved: :unprocessable_content,
      invalid_zip_code: :unprocessable_content,
      geocoding_service_unavailable: :service_unavailable,
      weather_service_unavailable: :service_unavailable
    }.each do |error_code, expected_status|
      context "when the service returns #{error_code}" do
        let(:failure_result) do
          Result.failure(ForecastError.new(code: error_code, user_message: "test error"))
        end

        before do
          allow_any_instance_of(Forecasts::GetForecast)
            .to receive(:call).with(address).and_return(failure_result)
        end

        it "returns #{expected_status}" do
          get forecast_path, params: { address: address }

          expect(response).to have_http_status(expected_status)
        end
      end
    end
  end
end
