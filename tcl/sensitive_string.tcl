# sensitive_string.tcl - SensitiveString implementation for Tcl
#
# A SensitiveString wraps a secret value and prevents accidental exposure
# by returning a SHA256 hash instead of the raw value when converted to string.
#
# Requires: Tcl 8.6+ (for TclOO), Tcllib (for sha2 package)

package require Tcl 9.0
package require sha256

namespace eval ::sensitivestring {
    variable version 1.0.0
}

# SensitiveString class using TclOO
oo::class create ::sensitivestring::SensitiveString {
    variable value

    # Constructor - stores the secret value
    constructor {secretValue} {
        set value $secretValue
    }

    # Returns the SHA256 hash of the value
    # This is the "safe" representation that can be logged
    method toString {} {
        # Convert to UTF-8 bytes for consistent hashing of Unicode
        set bytes [encoding convertto utf-8 $value]
        set hash [::sha2::sha256 -hex $bytes]
        return "sha256:$hash"
    }

    # Returns the raw plaintext value
    # Use this ONLY when you explicitly need the secret
    method getValue {} {
        return $value
    }

    # Returns the length of the underlying value without exposing it
    method length {} {
        return [string length $value]
    }

    # Check if two SensitiveStrings have the same underlying value
    # by comparing their hashes
    method equals {other} {
        if {$other eq ""} {
            return 0
        }
        # Compare hashes (safe comparison)
        return [expr {[my toString] eq [$other toString]}]
    }

    # Returns a dict representation suitable for JSON-like serialization
    # The value is replaced with the hash
    method toDict {} {
        return [dict create value [my toString]]
    }

    # Override the unknown method to provide helpful error messages
    method unknown {methodName args} {
        error "unknown method \"$methodName\": must be toString, getValue, length, equals, or toDict"
    }
}

# Factory function to create a new SensitiveString
proc ::sensitivestring::new {value} {
    return [::sensitivestring::SensitiveString new $value]
}

# Convert any input to a SensitiveString
# If already a SensitiveString, returns it unchanged
# If nil/empty, returns empty string
proc ::sensitivestring::sensitive {input} {
    if {$input eq ""} {
        return ""
    }
    
    # Check if it's already a SensitiveString object
    if {[::sensitivestring::isSensitiveString $input]} {
        return $input
    }
    
    # Otherwise, create a new SensitiveString
    return [::sensitivestring::new $input]
}

# Check if the input is a SensitiveString object
proc ::sensitivestring::isSensitiveString {input} {
    if {$input eq ""} {
        return 0
    }
    
    # Check if it's an object and an instance of SensitiveString
    if {[catch {info object class $input} classname]} {
        return 0
    }
    
    return [expr {$classname eq "::sensitivestring::SensitiveString"}]
}

# Extract the raw value from a SensitiveString or return the string as-is
# Returns a list: {value found}
proc ::sensitivestring::extractValue {input} {
    if {$input eq ""} {
        return [list "" 0]
    }
    
    if {[::sensitivestring::isSensitiveString $input]} {
        return [list [$input getValue] 1]
    }
    
    # Assume it's a regular string
    return [list $input 1]
}

# Extract the raw value, raising an error if input is invalid
proc ::sensitivestring::extractRequiredValue {input} {
    lassign [::sensitivestring::extractValue $input] value found
    if {!$found} {
        error "extractRequiredValue: input must be a string or SensitiveString"
    }
    return $value
}

# Replace SensitiveStrings in a data structure with their plaintext values
# Works recursively on dicts and lists
# WARNING: Use only when you explicitly need to serialize secrets
proc ::sensitivestring::plaintextReplacer {data} {
    if {$data eq ""} {
        return ""
    }
    
    # If it's a SensitiveString, return its value
    if {[::sensitivestring::isSensitiveString $data]} {
        return [$data getValue]
    }
    
    # If it looks like a dict (even number of elements, key-value pairs)
    if {[catch {dict size $data}] == 0 && [dict size $data] > 0} {
        set result [dict create]
        dict for {key val} $data {
            dict set result $key [::sensitivestring::plaintextReplacer $val]
        }
        return $result
    }
    
    # If it's a list, process each element
    if {[llength $data] > 1 || ([llength $data] == 1 && [lindex $data 0] ne $data)} {
        set result {}
        foreach item $data {
            lappend result [::sensitivestring::plaintextReplacer $item]
        }
        return $result
    }
    
    # Otherwise, return as-is
    return $data
}

# Safe logging helper - converts SensitiveStrings to their hash representation
proc ::sensitivestring::safeLog {data} {
    if {$data eq ""} {
        return ""
    }
    
    # If it's a SensitiveString, return its hash
    if {[::sensitivestring::isSensitiveString $data]} {
        return [$data toString]
    }
    
    # If it looks like a dict
    if {[catch {dict size $data}] == 0 && [dict size $data] > 0} {
        set result [dict create]
        dict for {key val} $data {
            dict set result $key [::sensitivestring::safeLog $val]
        }
        return $result
    }
    
    # If it's a list, process each element
    if {[llength $data] > 1 || ([llength $data] == 1 && [lindex $data 0] ne $data)} {
        set result {}
        foreach item $data {
            lappend result [::sensitivestring::safeLog $item]
        }
        return $result
    }
    
    return $data
}

# Package export
namespace eval ::sensitivestring {
    namespace export new sensitive isSensitiveString extractValue \
                     extractRequiredValue plaintextReplacer safeLog
}

package provide sensitivestring $::sensitivestring::version
