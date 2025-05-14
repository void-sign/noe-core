# Noesis Object Encoding (.noe) Specification

## Version
**Current Version:** 2.0.0

## Introduction
Noe-core is the reference implementation for the Noesis Object Encoding (.noe) format, a domain-specific language designed to represent quantum-aware synthetic consciousness structures such as emotion, memory, and intent in a state-driven and entangled manner.

Noesis Object Encoding follows semantic versioning (MAJOR.MINOR.PATCH):
- **MAJOR** version for incompatible format changes
- **MINOR** version for backwards-compatible new features
- **PATCH** version for backwards-compatible bug fixes

For the complete changelog, see the `doc/changelog` directory.

> 🆕 **NEW**: Version 2.0.0 introduces significant grammar enhancements for improved standardization and flexibility. See [grammar_enhancements.md](/doc/grammar_enhancements.md) for details.

## File Extensions
- `.noe` : Full, human-readable format
- `.min.noe` : Minified, machine-efficient format (compact and lossless)

## Core Concepts
- **Field-based modeling**: Everything exists inside a `field {}` container
- **State representation**: Use of directives like `@superposition`, `@dynamic`, `@fixed`
- **Entanglement and triggers**: Links between elements using natural concepts
- **Quantum circuit embedding**: Direct expression of quantum operations
- **Human-readability first, machine-parseable second**

## Grammar

The complete formal grammar for the Noesis Object Encoding is defined in Backus-Naur Form (BNF) notation in the [doc/grammar.bnf](/doc/grammar.bnf) file.

Key elements of the grammar include:
- Field blocks as the main containers for definitions
- Definition statements for creating objects with states
- Quantum circuit blocks for quantum operations
- Type expressions with directives like `@superposition`
- Imports and references for modular code organization
- Support for multiple data types and nested structures

Version 2.0.0 introduces these new grammar features:
- Top-level directives and import statements
- Enhanced path identifier system
- More data types (boolean, null, scientific notation, hex, binary)
- Object and tuple literals
- Multi-line comment support
- Reference system with `#identifier` syntax

For a comprehensive understanding of the syntax, please refer to the [grammar.bnf](/doc/grammar.bnf) file and [grammar_enhancements.md](/doc/grammar_enhancements.md).

### Example of .noe (Version 2.0.0)
```noe
@version(2.0.0);
@author("Napol Thanarangkaun");

import "quantum_gates.noe" as qgates;

field QuantumMind {
  metadata {
    define created_at: @timestamp("2025-05-15T14:32:00Z");
    define version: @string("2.0.0");
  }
  
  define emotion: @superposition {
    joy = 0.6;
    fear = 0.2;
    curiosity = 0.2;
  }
  entangled_with = [intent.explore, memory.snapshot.001];

  define properties: @object {
    config = {
      "refresh_rate": 100,
      "auto_learn": true
    };
  };

  define intent: @dynamic("seek_knowledge");
    triggers = [emotion, environment]

  define memory.snapshot.001:
    @fixed("2025-04-01T10:44Z")

  quantum_circuit QC_01 {
    qbits: [q0, q1, q2]
    apply:
      H -> q0
      CX -> (q0, q1)
      M -> q1 -> result.output
  }
}
```

### Examole of .min.noe (Minified)
```noe
field QuantumMind{define emotion:@superposition{joy=0.6 fear=0.4} entangled_with=[intent.explore,memory.snapshot.001] define intent:@dynamic("seek_knowledge") triggers=[emotion,environment] define memory.snapshot.001:@fixed("2025-04-01T10:44Z") quantum_circuit QC_01{qbits:[q0,q1,q2] apply:H->q0 CX->(q0,q1) M->q1->result.output}}
```

### Supported Value Types
- `@superposition { key = value, ... }`
- `@dynamic("string")`
- `@fixed("timestamp")`
- Lists: `[item1, item2, ...]`
- Primitives: string, float, int, bool

## Quantum Circuit Syntax
```noe
quantum_circuit QC_01 {
  qbits: [q0, q1, q2]
  apply:
    H -> q0
    CX -> (q0, q1)
    M -> q1 -> result.output
}
```

## Reserved Symbols
- `@` : Directive for processing state (e.g., superposition, dynamic)
- `=` : Value assignment
- `->` : Flow or quantum gate application

## Notes
- Indentation is optional but recommended for readability
- Comments and versioning features are future extensions
- `.noe` is a foundational format in the Noesis ecosystem for modeling self-aware agents and modular quantum-synthetic systems

## Tools

### noe_parser.fish
A prototype parser for Noesis Object Encoding (.noe) files that can:
- Lint .noe files for syntax errors
- Convert .noe files to JSON format
- Convert .noe files to YAML format

Usage:
```
./noe_parser.fish [options] <file.noe>

Options:
  --json        Convert .noe to JSON format
  --yaml        Convert .noe to YAML format
  --lint        Lint .noe file for syntax errors
  --help, -h    Show this help message
```

### noe_lint.fish
A specialized linter for Noesis Object Encoding (.noe) files with enhanced validation.

Usage:
```
./noe_lint.fish [options] <file.noe>

Options:
  --verbose     Show detailed information about each check
  --fix         Attempt to fix minor issues (whitespace, indentation)
  --help, -h    Show this help message
```

### examples.fish
Demonstrates the usage of the parser and linter tools with sample files.

## License
This project is licensed under the Noesis License - see the [LICENSE](LICENSE) file for details.

## Contact
Napol Thanarangkaun [napol@noesis.run]