# project-docs

This folder documents the work done in this repository with GitHub Copilot, so anyone can see
what was done, why, and how to reproduce it.

- `log.md` - every outcome-producing step, newest first. Only the top entry is current.
- `decisions.md` - decisions that shape the repository, with the reasons.
- `knowledge.md` - facts about the code, each citing its source file.
- `walkthrough.ai.md` - standalone step-by-step guide for an LLM to lead a user through the
  whole build. Created by `/project-docs-regenerate`.
- `walkthrough.md` - the same steps for human readers. Created by
  `/project-docs-regenerate human` or `both`.

The agent writes the log, decisions and knowledge entries while it works, following
`.github/instructions/project-docs.instructions.md`. The walkthroughs are generated only when
you run `/project-docs-regenerate`; do not edit them by hand.

Check health with `/project-docs status`. Remove the rules and hooks with `/project-docs disable`.
