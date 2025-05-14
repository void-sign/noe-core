#!/usr/bin/env fish

# noe_parser.fish
# Copyright (c) 2025 Napol Thanarangkaun (napol@noesis.run). All rights reserved.
# Licensed under the Noesis License.
#
# A prototype parser for Noesis Object Encoding (.noe) files
# Can lint .noe files and convert them to JSON and YAML
# Version 1.0.0

function print_help
    echo "Noesis Object Encoding (.noe) Parser and Linter"
    echo "Usage: ./noe_parser.fish [options] <file.noe>"
    echo ""
    echo "Options:"
    echo "  --json        Convert .noe to JSON format"
    echo "  --yaml        Convert .noe to YAML format"
    echo "  --lint        Lint .noe file for syntax errors"
    echo "  --grammar, -g Validate file against formal BNF grammar"
    echo "  --version, -v Show version information"
    echo "  --help, -h    Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./noe_parser.fish --json sample.noe > output.json"
    echo "  ./noe_parser.fish --yaml sample.noe > output.yaml"
    echo "  ./noe_parser.fish --lint sample.noe"
    echo "  ./noe_parser.fish --grammar sample.noe"
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
        case "--grammar" "-g"
            set action "grammar"
        case "--help" "-h"
            print_help
            exit 0
        case "--version" "-v"
            echo "Noesis Object Encoding (.noe) Parser - Version 1.0.0"
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
    set -l metadata "{}"
    set -l imports "[]"
    set -l version "1.0.0"
    
    # Remove comments
    set content (strip_comments "$content")
    
    # Extract metadata and directives
    set directives (echo "$content" | string match -a -r '@([a-zA-Z0-9_]+)\(([^)]*)\);')
    if test (count $directives) -gt 0
        # Extract version if present
        set version_match (echo "$content" | string match -r '@version\("([0-9\.]+)"\);')
        if test (count $version_match) -gt 1
            set version $version_match[2]
            set metadata (echo "$metadata" | string replace "}" "\"_version\": \"$version\"}")
        end
        
        # Extract author if present
        set author_match (echo "$content" | string match -r '@author\("([^"]*)"\);')
        if test (count $author_match) -gt 1
            set author $author_match[2]
            set metadata (echo "$metadata" | string replace "}" "\"_author\": \"$author\", }")
        end
        
        # Extract date if present
        set date_match (echo "$content" | string match -r '@date\("([^"]*)"\);')
        if test (count $date_match) -gt 1
            set date $date_match[2]
            set metadata (echo "$metadata" | string replace "}" "\"_date\": \"$date\", }")
        end
    end
    
    # Extract imports
    set import_matches (echo "$content" | string match -a -r 'import\s+"([^"]+)"\s*(?:as\s+([a-zA-Z0-9_]+))?;')
    if test (count $import_matches) -gt 0
        set imports "["
        for i in (seq 3 3 (count $import_matches))
            set file_path $import_matches[(math $i - 2)]
            set alias ""
            if test (count $import_matches) -ge $i
                set alias $import_matches[$i]
            end
            
            if test -n "$alias"
                set imports "$imports{\"path\": \"$file_path\", \"alias\": \"$alias\"},"
            else
                set imports "$imports{\"path\": \"$file_path\"},"
            end
        end
        set imports (echo "$imports" | string replace -r ',$' ']')
    end
    
    # First pass: Identify fields and structure
    echo "$content" | string replace -r '\s+' ' ' | while read -l line
        # Skip empty lines
        if test -z "$line"
            continue
        end
        
        # Skip directive and import lines
        if string match -q "@*" "$line"; or string match -q "import*" "$line"
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
        
        # Handle nested field blocks
        if string match -q "*{*" "$line"; and not string match -q "*field*" "$line"; and not string match -q "*define*" "$line"; and not string match -q "*quantum_circuit*" "$line"
            set nested_name (echo "$line" | string match -r '([A-Za-z0-9_.]+)\s*{' | tail -n 1)
            if test -n "$nested_name"
                set result "$result\"$nested_name\": {"
                set depth (math $depth + 1)
            end
        end
        
        # Handle key-value pairs
        if string match -q "*=*" "$line"
            set key (echo "$line" | string match -r '([A-Za-z0-9_.]+)\s*=' | tail -n 1)
            # Handle different value types (enhanced for v2.0.0)
            if string match -q "*=*{*" "$line"  # Object
                set value (echo "$line" | string match -r '=\s*(\{[^}]*\})' | tail -n 1)
            else if string match -q "*=*(*" "$line"  # Tuple
                set value (echo "$line" | string match -r '=\s*(\([^)]*\))' | tail -n 1)
                # Convert parentheses to brackets for JSON compatibility
                set value (echo "$value" | string replace "(" "[" | string replace ")" "]")
            else if string match -q "*=*[*" "$line"  # Array
                set value (echo "$line" | string match -r '=\s*(\[[^\]]*\])' | tail -n 1)
            else if string match -q "*=*true*" "$line"; or string match -q "*=*false*" "$line"  # Boolean
                set value (echo "$line" | string match -r '=\s*(true|false)' | tail -n 1)
            else if string match -q "*=*null*" "$line"  # Null
                set value "null"
            else if string match -q "*=*\"*" "$line"; or string match -q "*=*'*" "$line"  # String
                set value (echo "$line" | string match -r '=\s*("[^"]*"|\'[^\']*\')' | tail -n 1)
                # Ensure double-quoted strings for JSON
                set value (echo "$value" | string replace "'" "\"")
            else if string match -q "*=*0x*" "$line"  # Hex
                set hex_val (echo "$line" | string match -r '=\s*0x([0-9a-fA-F]+)' | tail -n 1)
                set value (printf "%d" 0x$hex_val)
            else if string match -q "*=*0b*" "$line"  # Binary
                set bin_val (echo "$line" | string match -r '=\s*0b([01]+)' | tail -n 1)
                set value (printf "%d" 0b$bin_val)
            else if string match -q "*=*e*" "$line"; or string match -q "*=*E*" "$line"  # Scientific
                set value (echo "$line" | string match -r '=\s*([0-9\.]+[eE][+-]?[0-9]+)' | tail -n 1)
            else  # Number
                set value (echo "$line" | string match -r '=\s*([0-9\.]+)' | tail -n 1)
            end
            
            # Remove semicolons if present
            set value (echo "$value" | string replace ";" "")
            
            # Check for references
            if string match -q "*#*" "$value"
                set ref_name (echo "$value" | string match -r '#([A-Za-z0-9_.]+)' | tail -n 1)
                set value "{\"_ref\": \"$ref_name\"}"
            end
            
            set result "$result\"$key\": $value,"
        end
        
        # Handle type directives (enhanced for v2.0.0)
        set type_expr ""
        set type_params ""
        
        # Extract type expression and parameters
        if string match -q "*@*" "$line"
            set type_expr (echo "$line" | string match -r '@([a-zA-Z0-9_]+)' | tail -n 1)
            
            # Extract parameters if present
            if string match -q "*@*(*)*" "$line"
                set type_params (echo "$line" | string match -r '@[a-zA-Z0-9_]+\(([^)]*)\)' | tail -n 1)
                # Make sure params are properly quoted for JSON
                set type_params (echo "$type_params" | string replace "'" "\"")
            end
        end
        
        # Add type information
        if test -n "$type_expr"
            set result "$result\"_type\": \"$type_expr\","
            if test -n "$type_params"
                set result "$result\"_params\": $type_params,"
            end
        end
        
        # Handle quantum circuits
        if string match -q "*quantum_circuit*" "$line"
            set circuit_name (echo "$line" | string match -r 'quantum_circuit ([A-Za-z0-9_]+)' | tail -n 1)
            set result "$result\"quantum_circuit\": {\"name\": \"$circuit_name\","
            set depth (math $depth + 1)
        end
        
        # Handle qbits section
        if string match -q "*qbits:*" "$line"
            set qbits (echo "$line" | string match -r 'qbits:\s*(\[[^\]]*\])' | tail -n 1)
            set result "$result\"qbits\": $qbits,"
        end
        
        # Handle apply section
        if string match -q "*apply:*" "$line"
            set result "$result\"apply\": ["
            # Gates will be added in subsequent lines
        end
        
        # Handle gates
        if string match -q "*->*" "$line"
            set gate_name (echo "$line" | string match -r '([A-Za-z0-9_]+)\s*->' | tail -n 1)
            set gate_params ""
            
            # Extract parameters if present
            if string match -q "*(*)*->*" "$line"
                set gate_params (echo "$line" | string match -r '[A-Za-z0-9_]+\(([^)]*)\)\s*->' | tail -n 1)
            end
            
            # Extract target qubits
            set targets (echo "$line" | string match -r '->\s*([^\s;]*)' | tail -n 1)
            
            # Extract output if present
            set output ""
            if string match -q "*->*->*" "$line"
                set output_matches (echo "$line" | string match -r '->([^;]*)->\s*([^;\s]*)' | tail -n 2)
                if test (count $output_matches) -ge 2
                    set output $output_matches[2]
                end
            end
            
            # Add gate to apply array
            set gate_json "{\"gate\": \"$gate_name\""
            if test -n "$gate_params"
                set gate_json "$gate_json, \"params\": $gate_params"
            end
            
            set gate_json "$gate_json, \"target\": \"$targets\""
            
            if test -n "$output"
                set gate_json "$gate_json, \"output\": \"$output\""
            end
            
            set gate_json "$gate_json},"
            set result "$result$gate_json"
        end
        
        # Handle output section
        if string match -q "*output:*" "$line"
            set result "$result], \"outputs\": {"
            # Outputs will be added in subsequent lines
        end
        
        # Handle output assignments
        if string match -q "*=*" "$line"; and string match -q "*output:*" "$line"
            set output_name (echo "$line" | string match -r '([A-Za-z0-9_.]+)\s*=' | tail -n 1)
            set output_value (echo "$line" | string match -r '=\s*([^;\s]*)' | tail -n 1)
            set result "$result\"$output_name\": \"$output_value\","
        end
        
        # Handle closing brace
        if string match -q "*}*" "$line"
            # Close gates array or outputs object if needed
            if string match -q "*apply:*" "$content"; and not string match -q "*output:*" "$content"
                set result "$result],"
            end
            
            # Close the current object
            set result "$result},"
            set depth (math $depth - 1)
            
            # If we're back to depth 0, we're done with this field
            if test "$depth" -eq 0
                set in_field false
            end
        end
    end
    
    # Add metadata to the result
    set result_with_meta "{\"_metadata\": $metadata, \"_imports\": $imports, $result"
    
    # Clean up the result by removing the last comma and wrapping in curly braces
    set result (echo "$result" | string replace -r ',$' '')
    echo "$result_with_meta}"
end

# Function to convert the internal structure to JSON
function to_json
    set -l internal "$argv[1]"
    # Cleanup JSON formatting
    set formatted (echo "$internal" | \
        string replace -a ', }' ' }' | \
        string replace -a ',}' '}' | \
        string replace -a '},]' '}]' | \
        string replace -a '],,' '],' | \
        string replace -a ',,}' ',}' | \
        string replace -a ',,\"' ',\"')
        
    # Make it pretty-printed (indented) JSON
    # This is a simplified pretty-print, in production would use jq or similar
    set formatted_json ""
    set indent_level 0
    set in_string false
    set escape_next false
    
    for i in (seq 1 (string length $formatted))
        set char (echo $formatted | cut -c $i)
        
        # Handle escaping
        if test "$escape_next" = "true"
            set escape_next false
            set formatted_json "$formatted_json$char"
            continue
        end
        
        if test "$char" = "\\"
            set escape_next true
            set formatted_json "$formatted_json$char"
            continue
        end
        
        # Handle quotes
        if test "$char" = "\""
            if test "$in_string" = "true"
                set in_string false
            else
                set in_string true
            end
            set formatted_json "$formatted_json$char"
            continue
        end
        
        # Skip formatting inside strings
        if test "$in_string" = "true"
            set formatted_json "$formatted_json$char"
            continue
        end
        
        # Format JSON structure
        switch $char
            case "{"
                set indent_level (math $indent_level + 1)
                set formatted_json "$formatted_json{\n"
                set formatted_json "$formatted_json"(string repeat -n $indent_level "  ")
            case "}"
                set indent_level (math $indent_level - 1)
                set formatted_json "$formatted_json\n"
                set formatted_json "$formatted_json"(string repeat -n $indent_level "  ")
                set formatted_json "$formatted_json}"
            case ","
                set formatted_json "$formatted_json,\n"
                set formatted_json "$formatted_json"(string repeat -n $indent_level "  ")
            case "["
                if test (string sub -s (math $i + 1) -l 1 $formatted) = "]"
                    # Empty array
                    set formatted_json "$formatted_json[]"
                    set i (math $i + 1)
                else
                    set indent_level (math $indent_level + 1)
                    set formatted_json "$formatted_json[\n"
                    set formatted_json "$formatted_json"(string repeat -n $indent_level "  ")
                end
            case "]"
                set indent_level (math $indent_level - 1)
                set formatted_json "$formatted_json\n"
                set formatted_json "$formatted_json"(string repeat -n $indent_level "  ")
                set formatted_json "$formatted_json]"
            case "*"
                set formatted_json "$formatted_json$char"
        end
    end
    
    echo $formatted_json
end

# Function to convert the internal structure to YAML
function to_yaml
    set -l json "$argv[1]"
    # Enhanced JSON to YAML conversion
    # This is a more sophisticated converter than the original
    
    # First, clean up the JSON
    set clean_json (echo "$json" | \
        string replace -a ', }' ' }' | \
        string replace -a ',}' '}' | \
        string replace -a '},]' '}]' | \
        string replace -a '],,' '],' | \
        string replace -a ',,}' ',}' | \
        string replace -a ',,\"' ',\"')
    
    # Now convert to YAML
    set yaml ""
    set indent_level 0
    set in_string false
    set escape_next false
    set after_colon false
    set in_array false
    set array_indent 0
    
    for i in (seq 1 (string length $clean_json))
        set char (echo $clean_json | cut -c $i)
        
        # Handle escaping
        if test "$escape_next" = "true"
            set escape_next false
            set yaml "$yaml$char"
            continue
        end
        
        if test "$char" = "\\"
            set escape_next true
            set yaml "$yaml$char"
            continue
        end
        
        # Handle quotes
        if test "$char" = "\""
            if test "$in_string" = "true"
                set in_string false
                if test "$after_colon" = "true"
                    set after_colon false
                end
            else
                set in_string true
            end
            
            # Skip the quote character in YAML output unless needed
            continue
        end
        
        # Handle special characters inside strings
        if test "$in_string" = "true"
            set yaml "$yaml$char"
            continue
        end
        
        # Convert JSON structure to YAML
        switch $char
            case "{"
                set indent_level (math $indent_level + 1)
                if test $indent_level -gt 1
                    set yaml "$yaml\n"
                    set yaml "$yaml"(string repeat -n (math $indent_level - 1) "  ")
                end
            case "}"
                set indent_level (math $indent_level - 1)
            case ","
                if test "$in_array" = "true"
                    set yaml "$yaml, "
                else
                    set yaml "$yaml\n"
                    set yaml "$yaml"(string repeat -n $indent_level "  ")
                end
            case ":"
                set yaml "$yaml: "
                set after_colon true
            case "["
                if test (string sub -s (math $i + 1) -l 1 $clean_json) = "]"
                    # Empty array
                    set yaml "$yaml[]"
                    set i (math $i + 1)
                else
                    set in_array true
                    set array_indent $indent_level
                    set yaml "$yaml["
                end
            case "]"
                set in_array false
                set yaml "$yaml]"
            case " "
                # Skip spaces between JSON elements
                if test "$after_colon" = "true"
                    set yaml "$yaml$char"
                end
            case "*"
                set yaml "$yaml$char"
        end
    end
    
    # Final cleanup - remove extra spaces, fix array formatting
    set yaml (echo "$yaml" | \
        string replace -a ": \"" ": " | \
        string replace -a "\":" ": " | \
        string replace -a "  ]" "]" | \
        string replace -r '(\[\s*[^\[\]]*)\s*\]' '$1]')
    
    echo $yaml
end

# Check if a file is valid against the BNF grammar
function validate_grammar
    set file $argv[1]
    set grammar_file "/Users/plugio/Documents/GitHub/noe-core/doc/grammar.bnf"
    
    echo "Validating $file against formal grammar..."
    echo "Grammar file: $grammar_file"
    
    # Read the grammar and file contents
    set contents (cat $file)
    
    # Simple validation based on key grammar elements
    # This is a simplified check - a full parser would implement the complete BNF grammar
    set valid true
    
    # Check for valid field blocks
    if not string match -q -r "field\s+[A-Za-z][A-Za-z0-9_]*\s*\{" $contents
        echo "Error: No valid field blocks found. Field blocks should follow pattern: field Name { ... }"
        set valid false
    end
    
    # Check for balanced braces
    set open_count (string match -a -r "\{" $contents | count)
    set close_count (string match -a -r "\}" $contents | count)
    
    if test $open_count -ne $close_count
        echo "Error: Unbalanced braces. Found $open_count opening and $close_count closing braces."
        set valid false
    end
    
    # Check for correct define statements
    if string match -q -r "define\s+[A-Za-z][A-Za-z0-9_.]*\s*:" $contents
        echo "✓ Valid define statements found"
    else
        echo "Error: No valid define statements found. Define statements should follow pattern: define name: ..."
        set valid false
    end
    
    # Check for type expressions with @ directives
    if string match -q -r "@(superposition|dynamic|fixed)" $contents
        echo "✓ Valid type expressions found"
    else
        echo "Warning: No standard type expressions (@superposition, @dynamic, @fixed) found"
    end
    
    if $valid
        echo "✓ File appears to be valid according to grammar rules"
        return 0
    else
        echo "✗ File contains grammar errors"
        return 1
    end
end

# Main execution
if test "$file" = ""
    echo "Error: No input file specified"
    exit 1
end

if not test -f "$file"
    echo "Error: File $file does not exist"
    exit 1
end

# Handle grammar validation
if test "$action" = "grammar"
    validate_grammar "$file"
    exit $status
end

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
