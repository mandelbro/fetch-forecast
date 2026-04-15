FactoryBot.define do
  factory :cached_forecast do
    sequence(:zip_code) { |n| "#{n}1001"[0, 5] }
    forecast_data { { "zip_code" => zip_code, "current" => { "temp" => 68.2 } } }
    expires_at { 30.minutes.from_now }

    trait :stale do
      expires_at { 5.minutes.ago }
      created_at { 10.minutes.ago }
      to_create { |instance| instance.save(validate: false) }
    end

    trait :realistic do
      forecast_data do
        {
          "zip_code"      => zip_code,
          "location_name" => "Cupertino",
          "country_code"  => "US",
          "fetched_at"    => fetched_at.iso8601,
          "units"         => "imperial",
          "current" => {
            "temp"        => 68.2,
            "feels_like"  => 66.4,
            "conditions"  => "Clear",
            "description" => "clear sky",
            "icon"        => "01d"
          },
          "today"    => { "high" => 72.5, "low" => 54.1 },
          "extended" => [
            { "date" => "2026-04-16", "high" => 71.8, "low" => 52.3, "conditions" => "Clouds", "icon" => "02d" }
          ]
        }
      end
    end
  end
end
