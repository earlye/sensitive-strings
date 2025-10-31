#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/sensitive_string'

puts "=== Ruby SensitiveString Tests ===\n\n"

# Test 1: to_s shows hash
password = SensitiveString.new('my-secret-password')
result = password.to_s
raise "Expected hash format" unless result.start_with?('sha256:')
raise "Leaked plaintext!" if result.include?('my-secret-password')
puts "✅ Test 1: to_s shows hash"

# Test 2: value returns plaintext
raise "value() failed" unless password.value == 'my-secret-password'
puts "✅ Test 2: value returns plaintext"

# Test 3: String interpolation
message = "Password: #{password}"
raise "Leaked in interpolation!" if message.include?('my-secret-password')
puts "✅ Test 3: String interpolation shows hash"

# Test 4: inspect
inspect_str = password.inspect
raise "inspect leaked!" if inspect_str.include?('my-secret-password')
puts "✅ Test 4: inspect shows hash"

# Test 5: JSON
require 'json'
data = { password: password }
json = JSON.generate(data)
raise "JSON leaked!" if json.include?('my-secret-password')
puts "✅ Test 5: JSON serialization shows hash"

# Test 6: Equality
password2 = SensitiveString.new('my-secret-password')
raise "Equality failed" unless password == password2
puts "✅ Test 6: Equality works"

# Test 7: Helper methods
raise "extract_value failed" unless SensitiveString.extract_value(password) == 'my-secret-password'
raise "extract_value failed" unless SensitiveString.extract_value('plain') == 'plain'
puts "✅ Test 7: Helper methods work"

# Test 8: Consistent hash
raise "Hash inconsistent" unless password.to_s == password2.to_s
puts "✅ Test 8: Consistent hash for same value"

puts "\n✨ All tests passed!"

