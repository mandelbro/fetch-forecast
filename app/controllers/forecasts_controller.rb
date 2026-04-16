class ForecastsController < ApplicationController
  STATUS_MAP = {
    address_not_resolved: :unprocessable_content,
    invalid_zip_code: :unprocessable_content,
    geocoding_service_unavailable: :service_unavailable,
    weather_service_unavailable: :service_unavailable
  }.freeze

  def new
  end

  def show
    address = params[:address].to_s.strip
    return redirect_to(root_path) if address.blank?

    result = Forecasts::GetForecast.new.call(address)

    if result.success?
      @response = result.value
      render :show
    else
      @address = address
      @error = result.error
      flash.now[:alert] = result.error.user_message
      render :new, status: status_for(result.error.code)
    end
  end

  private

  def status_for(code)
    STATUS_MAP.fetch(code, :unprocessable_content)
  end
end
