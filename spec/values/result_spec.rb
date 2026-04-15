# spec/values/result_spec.rb
# Explicit success/failure result value object
# class methods:
# - success(value) -> Result instance with succes? = true
# - failure(error) -> Result instance with success? = false
# public interface:
# - success? -> boolean
# - failure? -> boolean
# - value -> the wrapped value (nil if failure)
# - error -> the wrapped error (nil if success)
# - value_or(default) -> the wrapped value or the default value if the result is a failure

require 'rails_helper'

RSpec.describe Result, type: :value do
  describe ".success" do
    it "returns a Result instance with success? = true" do
      result = Result.success("success")
      expect(result.success?).to be_truthy
    end

    it "stores the value in the result" do
      result = Result.success("success")
      expect(result.value).to eq("success")
    end

    it "stores nil in the error" do
      result = Result.success("success")
      expect(result.error).to be_nil
    end
  end

  describe ".failure" do
    it "returns a Result instance with success? = false" do
      result = Result.failure("error")
      expect(result.success?).to be_falsey
    end

    it "stores the error in the result" do
      result = Result.failure("error")
      expect(result.error).to eq("error")
    end

    it "stores nil in the value" do
      result = Result.failure("error")
      expect(result.value).to be_nil
    end
  end

  describe "#value_or" do
    it "returns the wrapped value on success" do
      result = Result.success("success")
      expect(result.value_or("default")).to eq("success")
    end

    it "returns the default value on failure" do
      result = Result.failure("error")
      expect(result.value_or("default")).to eq("default")
    end
  end

  # it is frozen (immutable)
  describe "immutability" do
    it "is frozen after construction" do
    result = Result.success("success")
    expect { result.value = "new_value" }.to raise_error(FrozenError)
  end
end
