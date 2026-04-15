# spec/values/result_spec.rb

require 'rails_helper'

RSpec.describe Result, type: :value do
  describe ".success" do
    it "returns a Result instance with success? = true" do
      result = described_class.success("success")
      expect(result.success?).to be true
      expect(result.failure?).to be false
    end

    it "stores the value in the result" do
      result = described_class.success("success")
      expect(result.value).to eq("success")
      expect(result.error).to be_nil
    end

    it "stores nil in the error" do
      result = described_class.success("success")
      expect(result.error).to be_nil
    end
  end

  describe ".failure" do
    it "returns a Result instance with success? = false" do
      result = described_class.failure("error")
      expect(result).not_to be_success
      expect(result.failure?).to be true
    end

    it "stores the error in the result" do
      result = described_class.failure("error")
      expect(result.error).to eq("error")
    end

    it "stores nil in the value" do
      result = described_class.failure("error")
      expect(result.value).to be_nil
    end
  end

  describe "#value_or" do
    it "returns the wrapped value on success" do
      result = described_class.success("success")
      expect(result.value_or("default")).to eq("success")
    end

    it "returns the default value on failure" do
      result = described_class.failure("error")
      expect(result.value_or("default")).to eq("default")
    end
  end

  it "raises an error if initialized directly" do
    expect { described_class.new(success: true, value: "success", error: nil) }.to raise_error(NoMethodError)
  end

  # it is frozen (immutable)
  it "is frozen (immutable)" do
    result = described_class.success("success")
    expect(result).to be_frozen
  end
end
