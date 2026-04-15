class CachedForecast < ApplicationRecord
  validates :zip_code, presence: true, format: { with: /\A\d{5}\z/, message: "must be 5 digits" }, uniqueness: true
  validates :forecast_data, presence: true
  validates :expires_at,
    presence: { message: "time is required" },
    comparison: {
      # use a lambda to pass the current time to the comparison validator (vs server startup time)
      greater_than: ->(_record) { Time.current },
      message: "must be in the future"
    }

  scope :fresh, -> { where("expires_at > ?", Time.current) }
  scope :stale, -> { where("expires_at <= ?", Time.current) }
  scope :for_zip, ->(zip_code) { where(zip_code: zip_code) }

  def fresh?
    expires_at > Time.current
  end

  def stale?
    !fresh?
  end

  def age_seconds
    (Time.current - created_at).to_i
  end
end
