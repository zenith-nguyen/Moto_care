# Behavioural specifications (OpenSpec)

`openspec/` holds what the system must do, separate from the `docs/` guides that
explain how it is built. The format is [OpenSpec](https://github.com/Fission-AI/OpenSpec),
a plain-Markdown spec layer: no schema to learn, readable by a person and by an
AI coding tool.

## Layout

```
openspec/
├── config.yaml                 # project constraints that an agent cannot infer from code
├── specs/<capability>/spec.md  # current truth: what the system does today
└── changes/
    ├── <change-id>/            # a proposed behaviour change, not yet shipped
    │   ├── proposal.md         # why, and what is in and out of scope
    │   ├── specs/<capability>/spec.md   # the delta: ADDED / MODIFIED / REMOVED requirements
    │   ├── design.md           # technical direction, when the change needs one
    │   └── tasks.md            # implementation checklist
    └── archive/                # changes that shipped, kept with their date
```

## How a spec reads

Each capability spec states a purpose and then numbered obligations. A
requirement is a single testable statement using SHALL; each scenario names a
trigger and the observable outcome, so it maps onto a test:

```markdown
### Requirement: Payment confirmation
The system SHALL mark an order paid only after a SePay webhook for that payment
code passes signature and freshness verification.

#### Scenario: Unsigned callback
- **WHEN** a request arrives at the SePay webhook endpoint without a valid signature
- **THEN** the request is rejected and no payment state changes
```

## Working with them

- **Reading code?** Open the spec for that capability first. It is shorter than
  the code and states the rules the code is meant to satisfy.
- **Spec and code disagree?** That is a defect in one of them. Fix it or report
  it; do not work around it quietly.
- **Changing behaviour?** Create a change under `openspec/changes/`, get the
  proposal and the spec delta agreed, implement, then fold the delta into
  `openspec/specs/` and archive the change. Agents with skill support can read
  the workflow from `.agents/skills/`; the CLI (`npx @fission-ai/openspec`) has
  `list`, `status`, `validate` and `archive`.
- **Fixing a bug or refactoring without changing behaviour?** No change proposal
  is needed. The specs already describe the behaviour you are restoring.

The constraints in `openspec/config.yaml` are binding on every artifact: money
rules (integer minor units, webhook-confirmed income, manual payouts), the
public-repository rule that no real credential or account number appears in any
artifact, and the branch-protection rules that govern how work lands.
