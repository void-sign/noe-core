# Noesis Object Encoding (.noe) Specification

## Introduction
Noe-core is the reference implementation for the Noesis Object Encoding (.noe) format, a domain-specific language designed to represent quantum-aware synthetic consciousness structures such as emotion, memory, and intent in a state-driven and entangled manner.

## File Extensions
- `.noe` : Full, human-readable format
- `.min.noe` : Minified, machine-efficient format (compact and lossless)

## Core Concepts
- **Field-based modeling**: Everything exists inside a `field {}` container
- **State representation**: Use of directives like `@superposition`, `@dynamic`, `@fixed`
- **Entanglement and triggers**: Links between elements using natural concepts
- **Quantum circuit embedding**: Direct expression of quantum operations
- **Human-readability first, machine-parseable second**

## Grammar (Simplified BNF-like)

```
program        ::= { field_block }
field_block    ::= "field" identifier "{" { definition | quantum_block } "}"
definition     ::= "define" identifier ":" type_expr [ assignment ]
type_expr      ::= "@" identifier [ "(" literal ")" ] [ block ]
assignment     ::= identifier "=" value
block          ::= "{" { assignment } "}"
quantum_block  ::= "quantum_circuit" identifier "{" circuit_body "}"
circuit_body   ::= "qbits:" array "apply:" { gate_expr }
gate_expr      ::= identifier "->" identifier [ "->" identifier ]
array          ::= "[" [ value { "," value } ] "]"
value          ::= literal | identifier | array
identifier     ::= NAME | NAME "." NAME | NAME "_" NAME
literal        ::= string | number
```

### Examole of .noe (Full)
```noe
// declare a quantum field
field QuantumMind {
  define emotion:
    @superposition {
      joy = 0.6
      fear = 0.4
    }
    entangled_with = [intent.explore, memory.snapshot.001]

  define intent:
    @dynamic("seek_knowledge")
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