# Noesis Object Encoding (.noe) Grammar Enhancements

## Version 2.0.0 Improvements

This document outlines the enhancements made to the Noesis Object Encoding (.noe) grammar to make it more standard and flexible.

### 1. Enhanced Top-Level Structure

The grammar now supports multiple top-level elements:
- **Directives**: Allow for metadata and compiler instructions
- **Multiple Field Blocks**: Support for multiple independent field definitions
- **Import Statements**: Enable modular code organization

### 2. Improved Data Type Support

Added support for:
- **Boolean Values**: `true` and `false`
- **Null Values**: `null` for optional/undefined values
- **Scientific Notation**: `1.2e-6` for scientific numbers
- **Hexadecimal Numbers**: `0xFF` format for hex values
- **Binary Numbers**: `0b10101` format for binary values
- **Tuples**: Ordered collections with `(value1, value2, ...)`
- **Objects**: Key-value maps using JSON-like syntax

### 3. Enhanced Identifier and Path System

- **Path Identifiers**: More flexible dot notation for nested properties
- **Quoted Identifiers**: Support for spaces and special characters in names
- **References**: Reference other definitions with `#identifier` syntax

### 4. Modular Structure Support

- **Import System**: Import definitions from other .noe files
- **Aliasing**: Import with aliases for namespacing
- **References**: Cross-reference between different parts of code

### 5. Enhanced Quantum Circuit Syntax

- **Parameter Support**: Gate parameters with `Gate(params)`
- **Multiple Qubits**: More flexible qubit selection using tuples or arrays
- **Output Section**: Dedicated section for circuit outputs
- **Gate References**: Support for imported/user-defined gates

### 6. Improved Comment System

- **Single-line Comments**: Using `// comment`
- **Multi-line Comments**: Using `/* comment */` blocks

### 7. Standardized Syntax Features

- **Semicolons**: Optional semicolons for statement termination
- **Nested Blocks**: Support for nested field structures
- **Type Parameters**: Enhanced type expressions with parameters

### 8. Consistency and Organization

- **Consistent Block Structure**: All blocks follow a consistent pattern
- **Cleaner Quantum Circuit Syntax**: More readable quantum operations
- **Better Whitespace Handling**: More flexible formatting options

## Migration Notes

Existing .noe files (version 1.0.0) remain compatible with the new grammar. The enhancements are backward compatible but offer additional flexibility and features for new code.

## Additional Type Expressions

The new grammar extends the available type expressions:
- `@enum`: Enumerated value types
- `@timestamp`: Date/time values
- `@array`: Explicit array types
- `@object`: Complex object types
- `@tuple`: Ordered, fixed-size collections
- `@reference`: References to other definitions

These enhancements make the .noe format more suitable for complex data modeling while maintaining its quantum-aware capabilities.
