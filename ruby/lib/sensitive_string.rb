# frozen_string_literal: true

require 'digest/sha2'
require 'json'

# SensitiveString wraps a string value and prevents accidental exposure
# by returning a SHA256 hash instead of the raw value when formatted or serialized.
#
# The primary goal is to prevent ACCIDENTAL exposure. Intentional access
# to the plaintext is available via the +value+ method.
#
# Example:
#   password = SensitiveString.new("my-secret")
#   puts password  # => sha256:2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
#   password.value # => "my-secret" (intentional access)
class SensitiveString
  # @return [String] the plaintext value (use only when you need the actual secret)
  attr_reader :value

  # Creates a new SensitiveString
  #
  # @param value [String] the sensitive value to wrap
  def initialize(value)
    @value = value.freeze
    freeze
  end

  # Returns the SHA256 hash of the value instead of the plaintext.
  # This is called by puts, string interpolation, etc.
  #
  # @return [String] the SHA256 hash in format "sha256:hex"
  def to_s
    "sha256:#{hash_hex}"
  end

  # Returns a debug representation showing it's a SensitiveString with the hash.
  # This is called by p, inspect, debuggers, etc.
  #
  # @return [String] debug representation
  def inspect
    "#<SensitiveString:#{object_id} #{to_s}>"
  end

  # Returns the SHA256 hash for JSON serialization (json gem).
  #
  # @return [String] the SHA256 hash
  def to_json(*args)
    to_s.to_json(*args)
  end

  # Returns the SHA256 hash for Rails/ActiveSupport serialization.
  #
  # @return [String] the SHA256 hash
  def as_json(options = {})
    to_s
  end

  # Compare two SensitiveStrings by their raw values.
  #
  # @param other [Object] another object to compare against
  # @return [Boolean] true if both are SensitiveStrings with equal values
  def ==(other)
    other.is_a?(SensitiveString) && value == other.value
  end

  alias eql? ==

  # Make it hashable so it can be used as hash keys.
  #
  # @return [Integer] hash of the plaintext value
  def hash
    value.hash
  end

  # Returns the length of the underlying value without exposing it.
  #
  # @return [Integer] length of the plaintext
  def length
    value.length
  end

  alias size length

  # Returns true if the underlying value is empty.
  #
  # @return [Boolean] true if empty
  def empty?
    value.empty?
  end

  private

  # Computes the SHA256 hash as hex string
  #
  # @return [String] hex digest
  def hash_hex
    Digest::SHA256.hexdigest(value)
  end

  class << self
    # Checks if a value is a SensitiveString
    #
    # @param obj [Object] object to check
    # @return [Boolean] true if obj is a SensitiveString
    def sensitive_string?(obj)
      obj.is_a?(SensitiveString)
    end

    # Extracts the plaintext value from a String or SensitiveString
    #
    # @param obj [String, SensitiveString, nil] object to extract from
    # @return [String, nil] the plaintext value or nil
    def extract_value(obj)
      case obj
      when SensitiveString
        obj.value
      when String
        obj
      else
        nil
      end
    end

    # Extracts the plaintext value or raises an error
    #
    # @param obj [String, SensitiveString] object to extract from
    # @return [String] the plaintext value
    # @raise [ArgumentError] if obj is not a String or SensitiveString
    def extract_required_value(obj)
      result = extract_value(obj)
      raise ArgumentError, 'Expected String or SensitiveString' if result.nil?

      result
    end

    # Converts a value into a SensitiveString if it isn't already
    #
    # @param obj [Object] object to convert
    # @return [SensitiveString, nil] a SensitiveString or nil if obj was nil
    def sensitive(obj)
      return nil if obj.nil?
      return obj if obj.is_a?(SensitiveString)

      new(obj.to_s)
    end
  end
end

