#!/usr/bin/env fish

# yml_parser.fish
# Copyright (c) 2025 Napol Thanarangkaun (napol@noesis.run). All rights reserved.
# Licensed under the Noesis License.
#
# A prototype parser for YAML Markup Language (.yml) files
# Can lint .yml files and convert them to JSON and NOE
# Note: YML format doesn't have a minified version unlike NOE

function print_help
    echo "YAML Markup Language (.yml) Parser and Converter"
    echo "Usage: ./yml_parser.fish [options] <file.yml>"
    echo ""
    echo "Options:"
    echo "  --json        Convert .yml to JSON format"
    echo "  --noe         Convert .yml to NOE format"
    echo "  --lint        Lint .yml file for syntax errors"
    echo "  --help, -h    Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./yml_parser.fish --json sample.yml > output.json"
    echo "  ./yml_parser.fish --noe sample.yml > output.noe"
    echo "  ./yml_parser.fish --lint sample.yml"
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
        case "--noe"
            set action "noe"
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
if not string match -q "*.yml" "$file"; and not string match -q "*.yaml" "$file"
    echo "Warning: File '$file' does not have .yml or .yaml extension."
end

# Function to detect syntax errors in YAML files
function lint_yml
    set -l content "$argv[1]"
    set -l errors 0
    set -l lineno 1
    
    # Basic YAML syntax checks
    echo "$content" | while read -l line
        # Skip empty lines and comments
        if test -z "$line"; or string match -q "#*" "$line"
            set lineno (math $lineno + 1)
            continue
        end
        
        # Check for proper indentation (must be multiple of 2 spaces)
        set -l indent (echo "$line" | string match -r '^ *' | string length)
        if test (math $indent % 2) -ne 0
            echo "Line $lineno: Invalid indentation, must be multiple of 2 spaces: $line"
            set errors (math $errors + 1)
        end
        
        # Check for invalid colons (must have space after)
        if string match -q "*:*" "$line"; and not string match -q "*: *" "$line"; and not string match -q "*:$" "$line"
            echo "Line $lineno: Invalid colon usage, must have space after: $line"
            set errors (math $errors + 1)
        end
        
        # Check for common YAML syntax errors
        if string match -q "*[*" "$line"; and not string match -q "*[*]*" "$line"
            echo "Line $lineno: Possible unclosed array: $line"
            set errors (math $errors + 1)
        end
        
        # Check for tab characters (YAML prohibits tabs)
        if string match -q "*\t*" "$line"
            echo "Line $lineno: Tab characters are not allowed in YAML: $line"
            set errors (math $errors + 1)
        end
        
        set lineno (math $lineno + 1)
    end
    
    return $errors
end

# Function to convert YML to JSON
function yml_to_json
    set -l content "$argv[1]"
    
    # Using Python's PyYAML and JSON modules for conversion
    python3 -c "
import sys
import yaml
import json

try:
    yaml_content = sys.stdin.read()
    data = yaml.safe_load(yaml_content)
    json_output = json.dumps(data, indent=2)
    print(json_output)
except Exception as e:
    print(f'Error converting YAML to JSON: {e}', file=sys.stderr)
    sys.exit(1)
" <<< "$content"
    
    return $status
end

# Function to convert YML to NOE format
function yml_to_noe
    set -l content "$argv[1]"
    
    # Using Python for YAML to NOE conversion
    python3 -c "
import sys
import yaml

def yaml_to_noe(data, prefix=''):
    noe_output = []
    
    if isinstance(data, dict):
        for key, value in data.items():
            full_key = f'{prefix}{key}' if prefix else key
            
            if isinstance(value, dict):
                noe_output.append(yaml_to_noe(value, f'{full_key}.'))
            elif isinstance(value, list):
                noe_output.append(f'field {full_key} {{ type: array, value: {serialize_list(value)} }}')
            else:
                noe_output.append(f'field {full_key} {{ type: {get_type(value)}, value: {serialize_value(value)} }}')
    
    return '\\n'.join(noe_output)

def get_type(value):
    if isinstance(value, bool):
        return 'boolean'
    elif isinstance(value, (int, float)):
        return 'number'
    elif isinstance(value, str):
        return 'string'
    else:
        return 'unknown'

def serialize_value(value):
    if isinstance(value, bool):
        return 'true' if value else 'false'
    elif isinstance(value, (int, float)):
        return str(value)
    elif isinstance(value, str):
        # Escape quotes and newlines
        return f'\\\"{value.replace('\"', '\\\\\\\"\').replace('\\n', '\\\\n')}\\\"'
    return str(value)

def serialize_list(items):
    elements = []
    for item in items:
        if isinstance(item, (dict, list)):
            elements.append(serialize_complex_value(item))
        else:
            elements.append(serialize_value(item))
    
    return f'[{', '.join(elements)}]'

def serialize_complex_value(value):
    if isinstance(value, dict):
        parts = []
        for k, v in value.items():
            parts.append(f'{k}: {serialize_value(v)}')
        return f'{{{', '.join(parts)}}}'
    elif isinstance(value, list):
        return serialize_list(value)
    return serialize_value(value)

try:
    yaml_content = sys.stdin.read()
    data = yaml.safe_load(yaml_content)
    print(yaml_to_noe(data))
except Exception as e:
    print(f'Error converting YAML to NOE: {e}', file=sys.stderr)
    sys.exit(1)
" <<< "$content"
    
    return $status
end

# Main execution
if test -z "$action"; or test -z "$file"
    echo "Error: Please specify an action (--json, --noe, --lint) and a file."
    print_help
    exit 1
end

# Read file content
set content (cat "$file")

switch $action
    case "lint"
        echo "Linting YAML file: $file"
        lint_yml "$content"
        set exit_code $status
        
        if test $exit_code -eq 0
            echo "No syntax errors found."
        else
            echo "Found $exit_code error(s) in the YAML file."
        end
        exit $exit_code
    
    case "json"
        echo "Converting YAML to JSON: $file"
        yml_to_json "$content"
        
    case "noe"
        echo "Converting YAML to NOE: $file"
        yml_to_noe "$content"
end
