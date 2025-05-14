#!/usr/bin/env fish

# noe_parser.fish
# Copyright (c) 2025 Napol Thanarangkaun (napol@noesis.run). All rights reserved.
# Licensed under the Noesis License.
#
# A prototype parser for Noesis Object Encoding (.noe) files
# Can lint .noe files and convert them to JSON and YAML

function print_help
    echo "Noesis Object Encoding (.noe) Parser and Linter"
    echo "Usage: ./noe_parser.fish [options] <file.noe>"
    echo ""
    echo "Options:"
    echo "  --json        Convert .noe to JSON format"
    echo "  --yaml        Convert .noe to YAML format"
    echo "  --lint        Lint .noe file for syntax errors"
    echo "  --help, -h    Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./noe_parser.fish --json sample.noe > output.json"
    echo "  ./noe_parser.fish --yaml sample.noe > output.yaml"
    echo "  ./noe_parser.fish --lint sample.noe"
end

# Check if we have enough arguments
if test (count $argv) -lt 1
    print_help
    exit 1
end

# Parse arguments
set action ""
set file ""

for arg in $argv
    switch $arg
        case "--json"
            set action "json"
        case "--yaml"
            set action "yaml"
        case "--lint"
            set action "lint"
        case "--help" "-h"
            print_help
            exit 0
        case "*"
            # Last argument is considered as the file
            set file "$arg"
    end
end

# Check if file exists
if not test -f "$file"
    echo "Error: File '$file' does not exist."
    exit 1
end

# Check file extension
if not string match -q "*.noe" "$file"; and not string match -q "*.min.noe" "$file"
    echo "Warning: File '$file' does not have .noe or .min.noe extension."
end

# Function to strip comments
function strip_comments
    set -l content "$argv[1]"
    echo "$content" | string replace -r '//.*$' '' | string collect
end

# Function to detect syntax errors
function lint_noe
    set -l content "$argv[1]"
    set -l errors 0
    set -l lineno 1
    
    # Check for balanced braces
    set -l open_braces (echo "$content" | string match -a -r '{' | count)
    set -l close_braces (echo "$content" | string match -a -r '}' | count)
    
    if test "$open_braces" -ne "$close_braces"
        echo "Error: Unbalanced braces. Found $open_braces { and $close_braces }"
        set errors (math $errors + 1)
    end
    
    # Check each line for basic syntax
    echo "$content" | while read -l line
        set clean_line (echo "$line" | string replace -r '//.*$' '')
        
        # Check for field declaration
        if string match -q "*field*{*" "$clean_line"; and not string match -q "*field [A-Za-z0-9_]+*" "$clean_line"
            echo "Line $lineno: Invalid field declaration: $clean_line"
            set errors (math $errors + 1)
        end
        
        # Check for define statement
        if string match -q "*define*" "$clean_line"; and not string match -q "*define [A-Za-z0-9_.]+:*" "$clean_line"
            echo "Line $lineno: Invalid define statement: $clean_line"
            set errors (math $errors + 1)
        end
        
        # Check for quantum_circuit block
        if string match -q "*quantum_circuit*" "$clean_line"; and not string match -q "*quantum_circuit [A-Za-z0-9_]+*" "$clean_line"
            echo "Line $lineno: Invalid quantum_circuit statement: $clean_line"
            set errors (math $errors + 1)
        end
        
        set lineno (math $lineno + 1)
    end
    
    if test "$errors" -eq 0
        echo "Lint successful: No syntax errors found."
        return 0
    else
        echo "Lint failed: $errors syntax errors found."
        return 1
    end
end

# Basic parser to convert NOE to an internal structure
function parse_noe
    set -l content "$argv[1]"
    set -l result ""
    set -l depth 0
    set -l in_field false
    
    # Remove comments and whitespace
    set content (strip_comments "$content")
    
    # First pass: Identify fields and structure
    echo "$content" | string replace -r '\s+' ' ' | while read -l line
        # Skip empty lines
        if test -z "$line"
            continue
        end
        
        # Field declaration
        if string match -q "*field*" "$line"
            set field_name (echo "$line" | string match -r 'field ([A-Za-z0-9_]+)' | tail -n 1)
            set result "$result\"$field_name\": {"
            set in_field true
            set depth 1
            continue
        end
        
        # Define statement
        if string match -q "*define*" "$line"
            set element_name (echo "$line" | string match -r 'define ([A-Za-z0-9_.]+):' | tail -n 1)
            set result "$result\"$element_name\": {"
            set depth (math $depth + 1)
        end
        
        # Handle key-value pairs
        if string match -q "*=*" "$line"
            set key (echo "$line" | string match -r '([A-Za-z0-9_.]+)\s*=' | tail -n 1)
            set value (echo "$line" | string match -r '=\s*([0-9.]+|"[^"]*"|true|false|\[[^\]]*\])' | tail -n 1)
            set result "$result\"$key\": $value,"
        end
        
        # Handle superposition directive
        if string match -q "*@superposition*" "$line"
            set result "$result\"type\": \"superposition\","
        end
        
        # Handle dynamic directive
        if string match -q "*@dynamic*" "$line"
            set value (echo "$line" | string match -r '@dynamic\("([^"]*)"\)' | tail -n 1)
            set result "$result\"type\": \"dynamic\", \"value\": \"$value\","
        end
        
        # Handle fixed directive
        if string match -q "*@fixed*" "$line"
            set value (echo "$line" | string match -r '@fixed\("([^"]*)"\)' | tail -n 1)
            set result "$result\"type\": \"fixed\", \"timestamp\": \"$value\","
        end
        
        # Handle quantum circuits
        if string match -q "*quantum_circuit*" "$line"
            set circuit_name (echo "$line" | string match -r 'quantum_circuit ([A-Za-z0-9_]+)' | tail -n 1)
            set result "$result\"quantum_circuit\": {\"name\": \"$circuit_name\","
            set depth (math $depth + 1)
        end
        
        # Handle closing brace
        if string match -q "*}*" "$line"
            set result "$result},"
            set depth (math $depth - 1)
            
            # If we're back to depth 0, we're done with this field
            if test "$depth" -eq 0
                set in_field false
            end
        end
    end
    
    # Clean up the result by removing the last comma and wrapping in curly braces
    set result (echo "$result" | string replace -r ',$' '')
    echo "{$result}"
end

# Function to convert the internal structure to JSON
function to_json
    set -l internal "$argv[1]"
    echo "$internal" | string replace -a ', }' ' }' | string replace -a ',}' '}'
end

# Function to convert the internal structure to YAML
function to_yaml
    set -l json "$argv[1]"
    # Simple JSON to YAML conversion (for the prototype)
    # In a real implementation, you might use a dedicated JSON to YAML converter
    echo "$json" | string replace -a '{' '' | string replace -a '}' '' | \
        string replace -a ', ' '\n' | string replace -a '": ' ': ' | \
        string replace -a '"' ''
end

# Main execution
set content (cat "$file" | string collect)

switch $action
    case "lint"
        lint_noe "$content"
    case "json"
        set internal (parse_noe "$content")
        echo (to_json "$internal")
    case "yaml"
        set internal (parse_noe "$content")
        echo (to_yaml "$internal")
    case "*"
        echo "Error: No action specified. Use --json, --yaml, or --lint"
        print_help
        exit 1
end