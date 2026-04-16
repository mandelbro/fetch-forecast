Rails.application.routes.draw do
  root "forecasts#new"
  get "/forecast", to: "forecasts#show", as: :forecast
  get "up" => "rails/health#show", as: :rails_health_check
end
