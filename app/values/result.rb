# app/values/result.rb
# Explicit success/failure wrapper. Every service returns one.
# Immutable PORO with no dependencies.
#
# class methods:
# - success(value) -> Result instance with success? = true and value set
# - failure(error) -> Result instance with success? = false and error set
# public interface:
# - success? -> boolean
# - failure? -> boolean
# - value -> the wrapped value (nil if failure)
# - error -> the wrapped error (nil if success)
# - value_or(default) -> the wrapped value or the default value if the result is a failure
class Result
  attr_reader :value, :error

  def self.success(value)
    new(success: true, value: value)
  end

  def self.failure(error)
    new(success: false, error: error)
  end

  # make constructor private to force use of class methods
  private_class_method :new

  def initialize(success:, value: nil, error: nil)
    @success = success
    @value = value if success
    @error = error unless success
    freeze
  end

  def value_or(default)
    success? ? value : default
  end

  def success?
    @success
  end

  def failure?
    !success?
  end
end
