# Coding-agent entry point

> **Reviewing this repository for the university course?** Read
> [`CHAM-DIEM.md`](CHAM-DIEM.md) first (Vietnamese). It explains how to run the
> apps and the full test suite without any credentials, and states which single
> piece of configuration is deliberately withheld and why. A missing production
> `.env` is intentional, not an incomplete submission.

[`openspec/specs/`](openspec/specs/) states what the system must do, capability
by capability, in [OpenSpec](https://github.com/Fission-AI/OpenSpec) format. Read
the spec for a capability before changing its code, and treat a disagreement
between spec and code as a defect in one of them rather than something to work
around silently. Behaviour changes go through a change proposal under
`openspec/changes/`; `.agents/skills/` carries the workflow for agents that
support skills, and `npx @fission-ai/openspec --help` lists the CLI.

[`docs/SETUP.md`](docs/SETUP.md) brings a fresh clone to a running system with no
credentials: database, API, both apps, the seeded accounts to sign in with, and
the test suites. Follow it before concluding that something is broken.

Repository rules are maintained in [`docs/`](docs/README.md). Before proposing or changing code, read:

1. [`docs/AI_GUIDE.md`](docs/AI_GUIDE.md)
2. [`docs/WORKFLOW.md`](docs/WORKFLOW.md)
3. The contributor guide in [`docs/branches/`](docs/branches/)

This short entry point stays at the repository root so coding agents can discover the documentation automatically.
