#!/usr/bin/env tclsh
# test_sensitive_string.tcl - Tests for SensitiveString

package require Tcl 9.0

# Add current directory to auto_path for finding the package
lappend auto_path [file dirname [info script]]

source [file join [file dirname [info script]] sensitive_string.tcl]

# Simple test framework
namespace eval ::testing {
    variable passed 0
    variable failed 0
    variable errors {}
}

proc ::testing::assert {condition message} {
    # Use uplevel to evaluate condition in caller's context
    if {[uplevel 1 [list expr $condition]]} {
        incr ::testing::passed
        puts "  ✓ $message"
    } else {
        incr ::testing::failed
        lappend ::testing::errors $message
        puts "  ✗ FAILED: $message"
    }
}

proc ::testing::assertEqual {actual expected message} {
    if {$actual eq $expected} {
        incr ::testing::passed
        puts "  ✓ $message"
    } else {
        incr ::testing::failed
        lappend ::testing::errors "$message (expected: $expected, got: $actual)"
        puts "  ✗ FAILED: $message"
        puts "    Expected: $expected"
        puts "    Got:      $actual"
    }
}

proc ::testing::summary {} {
    puts ""
    puts "======================================"
    puts "Test Summary"
    puts "======================================"
    puts "Passed: $::testing::passed"
    puts "Failed: $::testing::failed"
    
    if {$::testing::failed > 0} {
        puts ""
        puts "Failures:"
        foreach err $::testing::errors {
            puts "  - $err"
        }
        return 1
    }
    return 0
}

# ============================================================
# Tests
# ============================================================

puts "======================================"
puts "SensitiveString TCL Tests"
puts "======================================"
puts ""

# Test 1: Basic creation and toString
puts "Test: Basic creation and toString"
set ss [::sensitivestring::new "secret123"]
set hash [$ss toString]
::testing::assert {[string match "sha256:*" $hash]} "toString returns sha256 prefixed hash"
::testing::assert {[string length $hash] == 71} "hash has correct length (sha256: + 64 hex chars)"

# Test 2: getValue returns original value
puts "\nTest: getValue returns original value"
set ss [::sensitivestring::new "my-secret-password"]
::testing::assertEqual [$ss getValue] "my-secret-password" "getValue returns original"

# Test 3: length returns correct length
puts "\nTest: length returns correct length"
set ss [::sensitivestring::new "12345"]
::testing::assertEqual [$ss length] 5 "length returns 5 for '12345'"

# Test 4: Same value produces same hash
puts "\nTest: Same value produces same hash"
set ss1 [::sensitivestring::new "identical"]
set ss2 [::sensitivestring::new "identical"]
::testing::assertEqual [$ss1 toString] [$ss2 toString] "identical values produce identical hashes"

# Test 5: Different values produce different hashes
puts "\nTest: Different values produce different hashes"
set ss1 [::sensitivestring::new "value1"]
set ss2 [::sensitivestring::new "value2"]
::testing::assert {[$ss1 toString] ne [$ss2 toString]} "different values produce different hashes"

# Test 6: equals method
puts "\nTest: equals method"
set ss1 [::sensitivestring::new "same"]
set ss2 [::sensitivestring::new "same"]
set ss3 [::sensitivestring::new "different"]
::testing::assert {[$ss1 equals $ss2]} "equals returns true for same value"
::testing::assert {![$ss1 equals $ss3]} "equals returns false for different value"

# Test 7: isSensitiveString
puts "\nTest: isSensitiveString"
set ss [::sensitivestring::new "test"]
::testing::assert {[::sensitivestring::isSensitiveString $ss]} "isSensitiveString returns true for SensitiveString"
::testing::assert {![::sensitivestring::isSensitiveString "plain string"]} "isSensitiveString returns false for plain string"
::testing::assert {![::sensitivestring::isSensitiveString ""]} "isSensitiveString returns false for empty string"

# Test 8: sensitive function
puts "\nTest: sensitive function"
set ss1 [::sensitivestring::sensitive "convert me"]
::testing::assert {[::sensitivestring::isSensitiveString $ss1]} "sensitive creates SensitiveString from string"
set ss2 [::sensitivestring::sensitive $ss1]
::testing::assert {$ss1 eq $ss2} "sensitive returns existing SensitiveString unchanged"

# Test 9: extractValue
puts "\nTest: extractValue"
set ss [::sensitivestring::new "extract-me"]
lassign [::sensitivestring::extractValue $ss] val found
::testing::assertEqual $val "extract-me" "extractValue returns value from SensitiveString"
::testing::assert {$found} "extractValue returns found=true for SensitiveString"

lassign [::sensitivestring::extractValue "plain"] val found
::testing::assertEqual $val "plain" "extractValue returns plain string as-is"
::testing::assert {$found} "extractValue returns found=true for plain string"

lassign [::sensitivestring::extractValue ""] val found
::testing::assert {!$found} "extractValue returns found=false for empty"

# Test 10: extractRequiredValue
puts "\nTest: extractRequiredValue"
set ss [::sensitivestring::new "required"]
::testing::assertEqual [::sensitivestring::extractRequiredValue $ss] "required" "extractRequiredValue returns value"

# Test extractRequiredValue error case
set errorCaught 0
if {[catch {::sensitivestring::extractRequiredValue ""} err]} {
    set errorCaught 1
}
::testing::assert {$errorCaught} "extractRequiredValue throws error for empty input"

# Test 11: plaintextReplacer
puts "\nTest: plaintextReplacer"
set ss [::sensitivestring::new "secret"]
::testing::assertEqual [::sensitivestring::plaintextReplacer $ss] "secret" "plaintextReplacer extracts value from SensitiveString"

set data [dict create username "user" password [::sensitivestring::new "pass123"]]
set replaced [::sensitivestring::plaintextReplacer $data]
::testing::assertEqual [dict get $replaced username] "user" "plaintextReplacer preserves plain values"
::testing::assertEqual [dict get $replaced password] "pass123" "plaintextReplacer replaces SensitiveString with value"

# Test 12: safeLog
puts "\nTest: safeLog"
set ss [::sensitivestring::new "logme"]
set logged [::sensitivestring::safeLog $ss]
::testing::assert {[string match "sha256:*" $logged]} "safeLog returns hash for SensitiveString"

set data [dict create username "user" password [::sensitivestring::new "secret"]]
set logged [::sensitivestring::safeLog $data]
::testing::assertEqual [dict get $logged username] "user" "safeLog preserves plain values"
::testing::assert {[string match "sha256:*" [dict get $logged password]]} "safeLog hashes SensitiveString in dict"

# Test 13: toDict method
puts "\nTest: toDict method"
set ss [::sensitivestring::new "dicttest"]
set d [$ss toDict]
::testing::assert {[dict exists $d value]} "toDict returns dict with 'value' key"
::testing::assert {[string match "sha256:*" [dict get $d value]]} "toDict value is the hash"

# Test 14: Known hash value (regression test)
puts "\nTest: Known hash value"
set ss [::sensitivestring::new "test"]
# SHA256 of "test" is 9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08
::testing::assertEqual [$ss toString] "sha256:9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08" "known hash value matches"

# Test 15: Empty string handling
puts "\nTest: Empty string handling"
set ss [::sensitivestring::new ""]
::testing::assertEqual [$ss length] 0 "empty string has length 0"
::testing::assertEqual [$ss getValue] "" "empty string getValue returns empty"
# SHA256 of empty string
::testing::assertEqual [$ss toString] "sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" "empty string hash is correct"

# Test 16: Unicode support
puts "\nTest: Unicode support"
set ss [::sensitivestring::new "héllo wörld 🔐"]
::testing::assertEqual [$ss getValue] "héllo wörld 🔐" "unicode value preserved"
::testing::assert {[string match "sha256:*" [$ss toString]]} "unicode value produces valid hash"

# Test 17: Accidental exposure protection
puts "\nTest: Accidental exposure protection"
set secret [::sensitivestring::new "super-secret-password"]

# In TCL, string interpolation gives the object reference, not the value
set interpolated "Password is: $secret"
::testing::assert {[string first "super-secret-password" $interpolated] == -1} "string interpolation does NOT expose secret"
::testing::assert {[string match "*::oo::Obj*" $interpolated]} "string interpolation shows object reference"

# Using append also doesn't expose the secret
set message "Credentials: "
append message $secret
::testing::assert {[string first "super-secret-password" $message] == -1} "append does NOT expose secret"

# The correct way to log - use safeLog which shows the hash
set credentials [dict create username "admin" password [::sensitivestring::new "hunter2"]]
set logOutput [::sensitivestring::safeLog $credentials]
::testing::assert {[string first "hunter2" $logOutput] == -1} "safeLog dict does NOT contain plaintext password"
::testing::assert {[string first "sha256:" $logOutput] != -1} "safeLog dict contains hash instead"
::testing::assertEqual [dict get $logOutput username] "admin" "safeLog preserves non-sensitive values"

# Test 18: JSON-like serialization scenario
puts "\nTest: JSON-like serialization scenario"
# Simulating what would happen if you tried to serialize credentials
set config [dict create \
    host "localhost" \
    port 5432 \
    api_key [::sensitivestring::new "sk-1234567890abcdef"]]

# "Accidentally" converting to string for logging
set configStr $config
::testing::assert {[string first "sk-1234567890abcdef" $configStr] == -1} "dict with SensitiveString doesn't expose secret in string form"

# Safe way to log config
set safeConfig [::sensitivestring::safeLog $config]
::testing::assert {[string first "sk-1234567890abcdef" $safeConfig] == -1} "safeLog config doesn't expose API key"
::testing::assert {[string match "*sha256:*" [dict get $safeConfig api_key]]} "safeLog config shows hash for API key"

# Test 19: Object destruction
puts "\nTest: Object destruction"
set ss [::sensitivestring::new "to-be-destroyed"]
::testing::assert {[::sensitivestring::isSensitiveString $ss]} "object exists before destroy"
$ss destroy
::testing::assert {![::sensitivestring::isSensitiveString $ss]} "object gone after destroy"

# Summary
puts ""
exit [::testing::summary]
