# Architecture Decision Records (ADRs)

This directory contains Architecture Decision Records (ADRs) documenting significant architectural decisions made in the Trading Cockpit project.

## What is an ADR?

An Architecture Decision Record (ADR) is a document that captures an important architectural decision made along with its context and consequences.

## ADR Format

Each ADR follows this structure:

- **Title**: Short noun phrase
- **Status**: Proposed, Accepted, Deprecated, Superseded
- **Context**: Forces at play (technical, political, social, project)
- **Decision**: The change we're proposing or have agreed to
- **Consequences**: What becomes easier or harder to do

## Index

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [ADR-001](001-actor-based-concurrency.md) | Actor-Based Concurrency for Thread Safety | Accepted | 2025-11-20 |
| [ADR-002](002-observable-macro-state-management.md) | Observable Macro for State Management | Accepted | 2025-11-20 |
| [ADR-003](003-asyncstream-for-market-data.md) | AsyncStream for Market Data Distribution | Accepted | 2025-11-21 |
| [ADR-004](004-realitykit-for-3d-visualization.md) | RealityKit for 3D Portfolio Visualization | Accepted | 2025-11-22 |
| [ADR-005](005-keychain-credential-storage.md) | Keychain for Secure Credential Storage | Accepted | 2025-11-20 |

## Creating a New ADR

When making a significant architectural decision:

1. Copy the template: `cp docs/adr/template.md docs/adr/NNN-title.md`
2. Fill in the sections
3. Submit for review via pull request
4. Update this README index

## Template

```markdown
# ADR-NNN: Title

## Status

[Proposed | Accepted | Deprecated | Superseded]

## Context

What is the issue that we're seeing that is motivating this decision or change?

## Decision

What is the change that we're proposing and/or doing?

## Consequences

What becomes easier or more difficult to do because of this change?

## Alternatives Considered

What other options were considered?

## References

- Link to relevant documentation
- Related ADRs
- External references
```

## Changing an ADR

- **Accepted ADRs** should not be modified except for clarifications
- To reverse a decision, create a new ADR that supersedes the old one
- Mark the old ADR as "Superseded by ADR-XXX"

## Related Resources

- [ADR Tools](https://github.com/npryce/adr-tools)
- [ADR GitHub Organization](https://adr.github.io/)
- [Thoughtworks Technology Radar - ADRs](https://www.thoughtworks.com/radar/techniques/lightweight-architecture-decision-records)
