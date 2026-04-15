class CreateCachedForecasts < ActiveRecord::Migration[8.0]
  def change
    create_table :cached_forecasts do |t|
      t.jsonb :forecast_data, null: false
      t.datetime :expires_at, null: false
      t.string :zip_code, null: false, limit: 5
      t.timestamps
    end

    # unique index for zip code
    add_index :cached_forecasts, :zip_code, unique: true
  end
end
