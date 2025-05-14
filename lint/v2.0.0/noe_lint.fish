#!/usr/bin/env fish

# noe_lint.fish
# Copyright (c) 2025 Napol Thanarangkaun (napol@noesis.run). All rights reserved.
# Licensed under the Noesis License.
#
# A specialized linter for Noesis Object Encoding (.noe) files
# Version 2.0.0

function print_help
    echo "Noesis Object Encoding (.noe) Linter"
    echo "Version 2.0.0"
    echo "Usage: ./noe_lint.fish [options] <file.noe>"
    echo ""
    echo "Options:"
    echo "  --verbose     Show detailed information about each check"
    echo "  --fix         Attempt to fix minor issues (whitespace, indentation)"
    echo "  --grammar     Validate against formal grammar.bnf"
    echo "  --version, -v Show version information"
    echo "  --help, -h    Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./noe_lint.fish sample.noe"
    echo "  ./noe_lint.fish --verbose sample.noe"
    echo "  ./noe_lint.fish --fix sample.min.noe"
    echo "  ./noe_lint.fish --grammar sample.noe"
end

# Check if we have enough arguments
if test (count $argv) -lt 1
    print_help
    exit 1
end

# Parse arguments
set verbose false
set fix false
set check_grammar false
set file ""

for arg in $argv
    switch $arg
        case "--verbose"
            set verbose true
        case "--fix"
            set fix true
        case "--grammar"
            set check_grammar true
        case "--version" "-v"
            echo "Noesis Object Encoding (.noe) Linter - Version 2.0.0"
            exit 0
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

# Function to validate directives
function check_directives
    set -l content "$argv[1]"
    set -l verbose "$argv[2]"
    set -l errors 0
    
    # Check for version directive
    set -l version_match (echo "$content" | string match -r '@version\("([0-9\.]+)"\);')
    if test (count $version_match) -gt 1
        set version $version_match[2]
        if test "$verbose" = "true"
            echo "✓ Found version directive: $version"
        end
    else
        echo "Warning: No @version directive found. Recommended format: @version(\"2.0.0\");"
    end
    
    # Check for author directive
    set -l author_match (echo "$content" | string match -r '@author\("([^"]*)"\);')
    if test (count $author_match) -gt 1
        set author $author_match[2]
        if test "$verbose" = "true"
            echo "✓ Found author directive: $author"
        end
    end
    
    # Check for other directives
    set -l directive_count (echo "$content" | string match -a -r '@[a-zA-Z0-9_]+\([^)]*\);' | count)
    if test "$directive_count" -gt 0; and test "$verbose" = "true"
        echo "✓ Found $directive_count directive(s) total"
    end
    
    # Check for import statements
    set -l import_count (echo "$content" | string match -a -r 'import "[^"]+";' | count)
    if test "$import_count" -gt 0; and test "$verbose" = "true"
        echo "✓ Found $import_count import statement(s)"
    end
    
    # Check for enhanced type expressions
    set -l type_expr (echo "$content" | string match -a -r '@(superposition|dynamic|fixed|enum|timestamp|array|object|tuple|reference|string|boolean|number|int)' | sort | uniq)
    if test (count $type_expr) -gt 0; and test "$verbose" = "true"
        echo "✓ Found type expressions: "(string join ", " $type_expr)
    end
    
    return 0 # Directives are optional in general
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

# Function to check balanced parentheses
function check_balanced_parentheses
    set -l content "$argv[1]"
    set -l verbose "$argv[2]"
    
    set -l open_parens (echo "$content" | string match -a -r '\(' | count)
    set -l close_parens (echo "$content" | string match -a -r '\)' | count)
    
    if test "$open_parens" -ne "$close_parens"
        echo "Error: Unbalanced parentheses. Found $open_parens ( and $close_parens )"
        return 1
    else if test "$verbose" = "true"
        echo "✓ Parentheses are balanced ($open_parens pairs)"
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
        if string match -q "*field*" "$current_line"; and not string match -q '//' "$current_line"; and not string match -q '/*' "$current_line"
            if not string match -q '*field [A-Za-z0-9_]+ {*' "$current_line"
                echo "Line $lineno: Invalid field declaration: $current_line"
                echo "  Proper format: field FieldName { ... }"
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
    
    set -l define_count (echo "$content" | string match -a -r 'define [A-Za-z0-9_.]+:' | count)
    
    if test "$define_count" -eq 0
        echo "Warning: No define statements found. Fields usually contain define statements."
    else if test "$verbose" = "true"
        echo "✓ Found $define_count define statement(s)"
    end
    
    # Check each define statement
    set -l lineno 1
    
    echo "$content" | while read -l line
        # Skip comments
        if string match -q '*//*' "$line"; or string match -q '*/\**' "$line"
            continue
        end
        
        if string match -q "*define*" "$line"
            if not string match -q '*define [A-Za-z0-9_.]+:*' "$line"
                echo "Line $lineno: Invalid define statement: $line"
                echo "  Proper format: define identifier: @type_expression [{ ... }];"
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
        # Skip comments
        if string match -q '*//*' "$line"; or string match -q '*/\**' "$line"
            continue
        end
        
        if string match -q "*quantum_circuit*" "$line"
            set in_circuit true
            set has_qbits false
            set has_apply false
            
            if not string match -q '*quantum_circuit [A-Za-z0-9_]+ {*' "$line"
                echo "Line $lineno: Invalid quantum_circuit declaration: $line"
                echo "  Proper format: quantum_circuit CircuitName { ... }"
                set errors (math $errors + 1)
            end
        end
        
        if test "$in_circuit" = "true"
            if string match -q "*qbits:*" "$line"
                set has_qbits true
                
                if not string match -q '*qbits: \[.*\]*' "$line"
                    echo "Line $lineno: Invalid qbits declaration: $line"
                    echo "  Proper format: qbits: [q0, q1, ...];"
                    set errors (math $errors + 1)
                end
            end
            
            if string match -q "*apply:*" "$line"
                set has_apply true
            end
            
            if string match -q "*->*" "$line"
                if not string match -q '.*-> ([A-Za-z0-9_]+|\[[^\]]+\]|\([^)]+\)).*' "$line"
                    echo "Line $lineno: Invalid gate application: $line"
                    echo "  Proper format: Gate -> qbit; or Gate -> (q0, q1); or Gate -> [q0, q1];"
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
    
    set -l single_comment_count (echo "$content" | string match -a -r '//' | count)
    
    # Check for balanced multi-line comments
    set -l multiline_begin (echo "$content" | string match -a -r '/\*' | count)
    set -l multiline_end (echo "$content" | string match -a -r '\*/' | count)
    
    if test "$multiline_begin" -ne "$multiline_end"
        echo "Error: Unbalanced multi-line comments. Found $multiline_begin /* and $multiline_end */"
        return 1
    end
    
    set -l total_comments (math $single_comment_count + $multiline_begin)
    
    if test "$total_comments" -gt 0; and test "$verbose" = "true"
        echo "✓ Found $single_comment_count single-line and $multiline_begin multi-line comment(s)"
    end
    
    return 0 # Comments are optional, so no errors if absent
end

# Function to check references
function check_references
    set -l content "$argv[1]"
    set -l verbose "$argv[2]"
    
    set -l ref_count (echo "$content" | string match -a -r '#[A-Za-z0-9_.]+' | count)
    
    if test "$ref_count" -gt 0; and test "$verbose" = "true"
        echo "✓ Found $ref_count reference(s)"
    end
    
    return 0 # References are optional
end

# Function to validate against grammar.bnf
function validate_grammar
    set -l file "$argv[1]"
    set -l grammar_file "/Users/plugio/Documents/GitHub/noe-core/doc/grammar.bnf"
    set -l verbose "$argv[2]"
    
    echo "Validating $file against formal grammar..."
    if test "$verbose" = "true"
        echo "Grammar file: $grammar_file"
    end
    
    # Read the grammar and file contents
    set contents (cat $file)
    
    # Simple validation based on key grammar elements from BNF
    set valid true
    
    # Check for valid field blocks
    if not string match -q -r "field\s+[A-Za-z][A-Za-z0-9_]*\s*\{" $contents
        echo "Error: No valid field blocks found. Field blocks should follow the pattern defined in grammar.bnf"
        set valid false
    else
        if test "$verbose" = "true"
            echo "✓ Valid field blocks found"
        end
    end
    
    # Check for valid directives
    if string match -q -r "@[a-zA-Z][a-zA-Z0-9_]*(\([^)]*\))?\s*;" $contents
        if test "$verbose" = "true"
            echo "✓ Valid directives found"
        end
    end
    
    # Check for valid imports
    if string match -q -r "import\s+\"[^\"]+\"\s*(as\s+[A-Za-z][A-Za-z0-9_]*)?\s*;" $contents
        if test "$verbose" = "true"
            echo "✓ Valid import statements found"
        end
    end
    
    # Check for valid define statements
    if string match -q -r "define\s+[A-Za-z][A-Za-z0-9_.]*\s*:" $contents
        if test "$verbose" = "true"
            echo "✓ Valid define statements found"
        end
    else
        echo "Error: No valid define statements found. Define statements should follow the pattern defined in grammar.bnf"
        set valid false
    end
    
    # Check for valid type expressions
    if string match -q -r "@(superposition|dynamic|fixed|enum|timestamp|array|object|tuple|reference|string|boolean|number|int)" $contents
        if test "$verbose" = "true"
            echo "✓ Valid type expressions found"
        end
    else
        echo "Warning: No standard type expressions found"
    end
    
    if $valid
        echo "✓ File appears to be valid according to grammar rules"
        return 0
    else
        echo "✗ File contains grammar errors"
        return 1
    end
end

# Function to validate data literals
function check_data_literals
    set -l content "$argv[1]"
    set -l verbose "$argv[2]"
    set -l errors 0
    
    # Check arrays
    set -l arrays (echo "$content" | string match -a -r '\[[^\]]*\]' | count)
    if test "$arrays" -gt 0; and test "$verbose" = "true"
        echo "✓ Found $arrays array literal(s)"
    end
    
    # Check objects
    set -l objects (echo "$content" | string match -a -r '{[^{}]*}' | count)
    if test "$objects" -gt 0; and test "$verbose" = "true"
        echo "✓ Found $objects object literal(s)"
    end
    
    # Check tuples
    set -l tuples (echo "$content" | string match -a -r '\([^()]*\)' | count)
    if test "$tuples" -gt 0; and test "$verbose" = "true"
        echo "✓ Found $tuples tuple literal(s)"
    end
    
    # Check for scientific notation
    set -l scientific (echo "$content" | string match -a -r '[0-9]+\.[0-9]*[eE][+-]?[0-9]+' | count)
    if test "$scientific" -gt 0; and test "$verbose" = "true"
        echo "✓ Found $scientific scientific notation value(s)"
    end
    
    # Check for hex values
    set -l hex (echo "$content" | string match -a -r '0x[0-9a-fA-F]+' | count)
    if test "$hex" -gt 0; and test "$verbose" = "true"
        echo "✓ Found $hex hexadecimal value(s)"
    end
    
    # Check for binary values
    set -l binary (echo "$content" | string match -a -r '0b[01]+' | count)
    if test "$binary" -gt 0; and test "$verbose" = "true"
        echo "✓ Found $binary binary value(s)"
    end
    
    # Check for boolean values
    set -l booleans (echo "$content" | string match -a -r '= (true|false)' | count)
    if test "$booleans" -gt 0; and test "$verbose" = "true"
        echo "✓ Found $booleans boolean value(s)"
    end
    
    # Check for null values
    set -l nulls (echo "$content" | string match -a -r '= null' | count)
    if test "$nulls" -gt 0; and test "$verbose" = "true"
        echo "✓ Found $nulls null value(s)"
    end
    
    return 0 # Data literals are optional
end

# Function to fix common issues
function fix_noe_file
    set -l file "$argv[1]"
    set -l is_min "$argv[2]"
    set -l content (cat "$file" | string collect)
    set -l fixed_content "$content"
    
    if test "$is_min" = "false"
        # Fix indentation (enhanced version)
        set -l depth 0
        set -l fixed_lines ""
        set -l in_multiline_comment false
        
        echo "$content" | while read -l line
            set -l clean_line (string trim "$line")
            
            # Handle multi-line comments
            if string match -q "/*" "$clean_line"; and not string match -q "*/" "$clean_line"
                set in_multiline_comment true
                set fixed_lines "$fixed_lines$clean_line
"
                continue
            end
            
            if test "$in_multiline_comment" = "true"
                if string match -q "*/" "$clean_line"
                    set in_multiline_comment false
                end
                set fixed_lines "$fixed_lines$clean_line
"
                continue
            end
            
            # Skip empty lines and comments
            if test -z "$clean_line"; or string match -q "// *" "$clean_line"; or string match -q "/* */" "$clean_line"
                set fixed_lines "$fixed_lines$clean_line
"
                continue
            end
            
            # Decrease depth for closing braces
            if string match -q "*}*" "$clean_line"; and not string match -q "*{*" "$clean_line"
                set depth (math $depth - 1)
            end
            
            # Add proper indentation
            set -l indent (string repeat ' ' (math $depth \* 2))
            set fixed_lines "$fixed_lines$indent$clean_line
"
            
            # Increase depth for opening braces
            if string match -q "*{*" "$clean_line"; and not string match -q "*}*" "$clean_line"
                set depth (math $depth + 1)
            end
        end
        
        set fixed_content "$fixed_lines"
        
        # Ensure semicolons are present where required
        set fixed_content (echo "$fixed_content" | string replace -r '(@[a-zA-Z0-9_]+\([^)]*\))(\s*[^;])' '$1;$2')
        set fixed_content (echo "$fixed_content" | string replace -r '(import "[^"]+")(\s*[^;])' '$1;$2')
        set fixed_content (echo "$fixed_content" | string replace -r '(define [A-Za-z0-9_.]+:.*?)(\s*$)' '$1;$2')
        
        # Fix spacing around operators
        set fixed_content (echo "$fixed_content" | string replace -a "= " "= " | string replace -a ":" " : " | string replace -a "->" " -> ")
        
    else
        # For minified files, create a proper minified version
        # Remove all whitespace except in strings
        set cleaned_content ""
        set in_string false
        set escape_next false
        
        for i in (seq 1 (string length $content))
            set char (echo $content | cut -c $i)
            
            # Handle escaping
            if test "$escape_next" = "true"
                set escape_next false
                set cleaned_content "$cleaned_content$char"
                continue
            end
            
            if test "$char" = "\\"
                set escape_next true
                set cleaned_content "$cleaned_content$char"
                continue
            end
            
            # Handle quotes
            if test "$char" = "\""; or test "$char" = "'"
                if test "$in_string" = "true"
                    set in_string false
                else
                    set in_string true
                end
                set cleaned_content "$cleaned_content$char"
                continue
            end
            
            # Keep all characters in strings
            if test "$in_string" = "true"
                set cleaned_content "$cleaned_content$char"
                continue
            end
            
            # Remove comments
            if test "$i" -lt (math (string length $content) - 1); and test "$char" = "/"; and test (echo $content | cut -c (math $i + 1)) = "/"
                # Skip to end of line
                set next_newline (echo $content | string match -r -i "$i,.*\n" | string length)
                if test -n "$next_newline"
                    set i (math $i + $next_newline - 1)
                else
                    set i (string length $content)
                end
                continue
            end
            
            if test "$i" -lt (math (string length $content) - 1); and test "$char" = "/"; and test (echo $content | cut -c (math $i + 1)) = "*"
                # Skip to end of multi-line comment
                set comment_end (echo $content | string match -r -i "$i,.*\*/" | string length)
                if test -n "$comment_end"
                    set i (math $i + $comment_end)
                else
                    set i (string length $content)
                end
                continue
            end
            
            # Skip whitespace
            if string match -q "[ \t\n\r]" "$char"
                continue
            end
            
            set cleaned_content "$cleaned_content$char"
        end
        
        set fixed_content $cleaned_content
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

# First check directives and general format
check_directives "$content" "$verbose"

if not check_balanced_braces "$content" "$verbose"
    set errors (math $errors + 1)
end

if not check_balanced_parentheses "$content" "$verbose"
    set errors (math $errors + 1)
end

if not check_comments "$content" "$verbose"
    set errors (math $errors + 1)
end

if not check_field_declarations "$content" "$verbose"
    set errors (math $errors + 1)
end

if not check_define_statements "$content" "$verbose"
    set errors (math $errors + 1)
end

if not check_quantum_circuits "$content" "$verbose"
    set errors (math $errors + 1)
end

# Check enhanced v2.0.0 features
check_references "$content" "$verbose"
check_data_literals "$content" "$verbose"

# Validate against grammar if requested
if test "$check_grammar" = "true"
    if not validate_grammar "$file" "$verbose"
        set errors (math $errors + 1)
    end
end

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
