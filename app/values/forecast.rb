# app/values/forecast.rb
# Purpose: Typed representation of a weather forecast.
# Immutable struct with keyword_init: true.
#
# Class Methods
# - Forecast.from_hash(hash) -> Forecast instance
#
# Public Interface
# - current_temp -> Float
# - feels_like -> Float
# - high -> Float
# - low -> Float
# - conditions -> String
# - extended -> Array of Hashes
# - zip_code -> String
# - location_name -> String
# - country_code -> String
# - fetched_at -> Time
# - to_h -> Hash

Forecast = Struct.new(
  :current_temp,
  :feels_like,
  :high,
  :low,
  :conditions,
  :extended,
  :zip_code,
  :location_name,
  :country_code,
  :fetched_at,
  keyword_init: true
) do
  def initialize(**kwargs)
    super(**kwargs)
    freeze
  end

  def self.from_hash(hash)
    new(
      current_temp: hash["current_temp"],
      feels_like: hash["feels_like"],
      high: hash["high"],
      low: hash["low"],
      conditions: hash["conditions"],
      extended: [ *hash["extended"] ].freeze,
      zip_code: hash["zip_code"],
      location_name: hash["location_name"],
      country_code: hash["country_code"],
      fetched_at: hash["fetched_at"].presence && Time.parse(hash["fetched_at"]), # nil if missing
    )
  end

  def to_h
    {
      "current_temp" => current_temp,
      "feels_like" => feels_like,
      "high" => high,
      "low" => low,
      "conditions" => conditions,
      "extended" => extended,
      "zip_code" => zip_code,
      "location_name" => location_name,
      "country_code" => country_code,
      "fetched_at" => fetched_at ? fetched_at.iso8601 : nil
    }
  end
end
