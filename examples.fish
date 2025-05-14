#!/usr/bin/env fish

# examples.fish
# Copyright (c) 2025 Napol Thanarangkaun (napol@noesis.run). All rights reserved.
# Licensed under the Noesis License.
#
# Examples of using the NOE parser and linter

echo "Noesis Object Encoding (.noe) Tools Examples"
echo "============================================="
echo ""

# Make scripts executable
chmod +x ./noe_parser.fish
chmod +x ./noe_lint.fish

echo "Example 1: Linting a .noe file"
echo "-----------------------------"
./noe_lint.fish --verbose sample.noe
echo ""

echo "Example 2: Validating against formal BNF grammar"
echo "--------------------------------------------"
./noe_parser.fish --grammar sample.noe
echo ""

echo "Example 2: Converting .noe to JSON"
echo "--------------------------------"
./noe_parser.fish --json sample.noe > sample.json
echo "Converted to sample.json"
cat sample.json | head -n 10
echo "..."
echo ""

echo "Example 3: Converting .noe to YAML"
echo "--------------------------------"
./noe_parser.fish --yaml sample.noe > sample.yaml
echo "Converted to sample.yaml"
cat sample.yaml | head -n 10
echo "..."
echo ""

echo "Example 4: Using with minified .noe files"
echo "---------------------------------------"
./noe_parser.fish --json sample.min.noe > sample.min.json
echo "Converted minified .noe to JSON"
cat sample.min.json | head -n 10
echo "..."
echo ""

echo "Examples completed. You can now use these tools for your .noe files."
