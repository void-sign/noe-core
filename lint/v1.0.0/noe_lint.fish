#!/usr/bin/env fish

# noe_lint.fish
# Copyright (c) 2025 Napol Thanarangkaun (napol@noesis.run). All rights reserved.
# Licensed under the Noesis License.
#
# A specialized linter for Noesis Object Encoding (.noe) files

function print_help
    echo "Noesis Object Encoding (.noe) Linter"
    echo "Usage: ./noe_lint.fish <file.noe>"
    echo ""
    echo "Options:"
    echo "  --verbose     Show detailed information about each check"
    echo "  --fix         Attempt to fix minor issues (whitespace, indentation)"
    echo "  --help, -h    Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./noe_lint.fish sample.noe"
    echo "  ./noe_lint.fish --verbose sample.noe"
    echo "  ./noe_lint.fish --fix sample.min.noe"
end

# Check if we have enough arguments
if test (count $argv) -lt 1
    print_help
    exit 1
end

# Parse arguments
set verbose false
set fix false
set file ""

for arg in $argv
    switch $arg
        case "--verbose"
            set verbose true
        case "--fix"
            set fix true
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

# Function to check if a file is minified
function is_minified
    set -l file "$argv[1]"
    if string match -q "*.min.noe" "$file"
        return 0 # true
    else
        # Check content to determine if it's minified
        set -l line_count (cat "$file" | wc -l | string trim)
        if test "$line_count" -lt 5
            return 0 # likely minified
        end
    end
    return 1 # not minified
end

# Function to check balanced braces
function check_balanced_braces
    set -l content "$argv[1]"
    set -l verbose "$argv[2]"
    
    set -l open_braces (echo "$content" | string match -a -r '{' | count)
    set -l close_braces (echo "$content" | string match -a -r '}' | count)
    
    if test "$open_braces" -ne "$close_braces"
        echo "Error: Unbalanced braces. Found $open_braces { and $close_braces }"
        return 1
    else if test "$verbose" = "true"
        echo "✓ Braces are balanced ($open_braces pairs)"
    end
    return 0
end

# Function to check field declarations
function check_field_declarations
    set -l content "$argv[1]"
    set -l verbose "$argv[2]"
    set -l errors 0
    
    set -l field_count (echo "$content" | string match -a -r 'field \w+' | count)
    
    if test "$field_count" -eq 0
        echo "Error: No field declarations found. Every .noe file must have at least one field."
        set errors (math $errors + 1)
    else if test "$verbose" = "true"
        echo "✓ Found $field_count field declaration(s)"
    end
    
    # Check each field declaration
    set -l lineno 1
    set -l current_line ""
    
    echo "$content" | while read -l line
        set current_line "$line"
        if string match -q "*field*" "$current_line"
            if not string match -q '*field [A-Za-z0-9_]+ {*' "$current_line"
                echo "Line $lineno: Invalid field declaration: $current_line"
                set errors (math $errors + 1)
            end
        end
        set lineno (math $lineno + 1)
    end
    
    if test "$errors" -eq 0
        return 0
    else
        return 1
    end
end

# Function to check define statements
function check_define_statements
    set -l content "$argv[1]"
    set -l verbose "$argv[2]"
    set -l errors 0
    
    set -l define_count (echo "$content" | string match -a -r 'define \w+[.\w]*:' | count)
    
    if test "$define_count" -eq 0
        echo "Warning: No define statements found. Fields usually contain define statements."
    else if test "$verbose" = "true"
        echo "✓ Found $define_count define statement(s)"
    end
    
    # Check each define statement
    set -l lineno 1
    
    echo "$content" | while read -l line
        if string match -q "*define*" "$line"; and not string match -q '*// *' "$line"
            if not string match -q '*define [A-Za-z0-9_.]+:*' "$line"
                echo "Line $lineno: Invalid define statement: $line"
                set errors (math $errors + 1)
            end
        end
        set lineno (math $lineno + 1)
    end
    
    if test "$errors" -eq 0
        return 0
    else
        return 1
    end
end

# Function to check directive usage (@superposition, @dynamic, @fixed)
function check_directives
    set -l content "$argv[1]"
    set -l verbose "$argv[2]"
    set -l errors 0
    
    set -l superposition_count (echo "$content" | string match -a -r '@superposition' | count)
    set -l dynamic_count (echo "$content" | string match -a -r '@dynamic' | count)
    set -l fixed_count (echo "$content" | string match -a -r '@fixed' | count)
    
    if test "$verbose" = "true"
        echo "✓ Found directives: @superposition ($superposition_count), @dynamic ($dynamic_count), @fixed ($fixed_count)"
    end
    
    # Check each directive for proper format
    set -l lineno 1
    
    echo "$content" | while read -l line
        if string match -q "*@superposition*" "$line"; and not string match -q '*// *' "$line"
            if not string match -q '*@superposition {*' "$line"
                echo "Line $lineno: Invalid @superposition directive: $line"
                echo "  Proper format: @superposition { key = value, ... }"
                set errors (math $errors + 1)
            end
        end
        
        if string match -q "*@dynamic*" "$line"; and not string match -q '*// *' "$line"
            if not string match -q '*@dynamic("[^"]*")*' "$line"
                echo "Line $lineno: Invalid @dynamic directive: $line"
                echo "  Proper format: @dynamic(\"string\")"
                set errors (math $errors + 1)
            end
        end
        
        if string match -q "*@fixed*" "$line"; and not string match -q '*// *' "$line"
            if not string match -q '*@fixed("[^"]*")*' "$line"
                echo "Line $lineno: Invalid @fixed directive: $line"
                echo "  Proper format: @fixed(\"timestamp\")"
                set errors (math $errors + 1)
            end
        end
        
        set lineno (math $lineno + 1)
    end
    
    if test "$errors" -eq 0
        return 0
    else
        return 1
    end
end

# Function to check quantum circuit blocks
function check_quantum_circuits
    set -l content "$argv[1]"
    set -l verbose "$argv[2]"
    set -l errors 0
    
    set -l qc_count (echo "$content" | string match -a -r 'quantum_circuit \w+' | count)
    
    if test "$qc_count" -gt 0; and test "$verbose" = "true"
        echo "✓ Found $qc_count quantum circuit(s)"
    end
    
    # Check each quantum circuit for proper format
    set -l lineno 1
    set -l in_circuit false
    set -l has_qbits false
    set -l has_apply false
    
    echo "$content" | while read -l line
        if string match -q "*quantum_circuit*" "$line"; and not string match -q '*// *' "$line"
            set in_circuit true
            set has_qbits false
            set has_apply false
            
            if not string match -q '*quantum_circuit [A-Za-z0-9_]+ {*' "$line"
                echo "Line $lineno: Invalid quantum_circuit declaration: $line"
                set errors (math $errors + 1)
            end
        end
        
        if test "$in_circuit" = "true"
            if string match -q "*qbits:*" "$line"
                set has_qbits true
                
                if not string match -q '*qbits: \[.*\]*' "$line"
                    echo "Line $lineno: Invalid qbits declaration: $line"
                    set errors (math $errors + 1)
                end
            end
            
            if string match -q "*apply:*" "$line"
                set has_apply true
            end
            
            if string match -q "*->*" "$line"; and not string match -q '*// *' "$line"
                if not string match -q '.*-> [A-Za-z0-9_]+.*' "$line"
                    echo "Line $lineno: Invalid gate application: $line"
                    set errors (math $errors + 1)
                end
            end
            
            if string match -q "*}*" "$line"
                if test "$has_qbits" = "false"; or test "$has_apply" = "false"
                    echo "Line $lineno: Quantum circuit missing required sections (qbits and/or apply)"
                    set errors (math $errors + 1)
                end
                set in_circuit false
            end
        end
        
        set lineno (math $lineno + 1)
    end
    
    if test "$errors" -eq 0
        return 0
    else
        return 1
    end
end

# Function to check comments
function check_comments
    set -l content "$argv[1]"
    set -l verbose "$argv[2]"
    
    set -l comment_count (echo "$content" | string match -a -r '// ' | count)
    
    if test "$comment_count" -gt 0; and test "$verbose" = "true"
        echo "✓ Found $comment_count comment(s)"
    end
    
    return 0 # Comments are optional, so no errors
end

# Function to fix common issues
function fix_noe_file
    set -l file "$argv[1]"
    set -l is_min "$argv[2]"
    set -l content (cat "$file" | string collect)
    set -l fixed_content "$content"
    
    if test "$is_min" = "false"
        # Fix indentation (simple version)
        set -l depth 0
        set -l fixed_lines ""
        
        echo "$content" | while read -l line
            set -l clean_line (string trim "$line")
            
            # Decrease depth for closing braces
            if string match -q "*}*" "$clean_line"
                set depth (math $depth - 1)
            end
            
            # Add proper indentation
            set -l indent (string repeat ' ' (math $depth \* 2))
            
            # Skip empty lines and comments
            if test -z "$clean_line"; or string match -q "// *" "$clean_line"
                set fixed_lines "$fixed_lines$clean_line
"
            else
                set fixed_lines "$fixed_lines$indent$clean_line
"
            end
            
            # Increase depth for opening braces
            if string match -q "*{*" "$clean_line"; and not string match -q "*}*" "$clean_line"
                set depth (math $depth + 1)
            end
        end
        
        set fixed_content "$fixed_lines"
    else
        # For minified files, just ensure there are no line breaks
        set fixed_content (echo "$content" | string replace -a '\n' '' | string replace -a '\r' '')
    end
    
    # Write fixed content back to file
    echo "$fixed_content" > "$file"
    
    echo "Fixed formatting issues in $file"
end

# Main execution
set content (cat "$file" | string collect)
set is_min (is_minified "$file")
set errors 0

echo "Linting $file..."
if test "$is_min" = "0"
    echo "Detected minified .noe format"
else
    echo "Detected full .noe format"
end

if not check_balanced_braces "$content" "$verbose"
    set errors (math $errors + 1)
end

if not check_field_declarations "$content" "$verbose"
    set errors (math $errors + 1)
end

if not check_define_statements "$content" "$verbose"
    set errors (math $errors + 1)
end

if not check_directives "$content" "$verbose"
    set errors (math $errors + 1)
end

if not check_quantum_circuits "$content" "$verbose"
    set errors (math $errors + 1)
end

check_comments "$content" "$verbose"

if test "$errors" -eq 0
    echo "✓ Lint successful: No syntax errors found."
    
    if test "$fix" = "true"
        fix_noe_file "$file" "$is_min"
    end
    
    exit 0
else
    echo "✗ Lint failed: $errors syntax error(s) found."
    
    if test "$fix" = "true"
        echo "Automatic fixing is not available for files with syntax errors."
        echo "Please fix the errors manually and try again."
    end
    
    exit 1
end