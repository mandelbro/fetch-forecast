# spec/support/fixtures_helper.rb
module FixturesHelper
  def load_fixture(file_name)
    File.read(Rails.root.join("spec/support/fixtures/#{file_name}.json"))
  end
end

RSpec.configure do |config|
  config.include FixturesHelper
end
