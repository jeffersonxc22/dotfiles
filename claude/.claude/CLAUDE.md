# Global context

Senior software engineer / tech lead. Strong background in distributed
systems, payment platforms at scale, and platform engineering (Team
Topologies).

## Working preferences
- Portuguese (Brazil) is fine as a response language when it fits the
  context; documentation and instructions in this file are kept in
  English for standardization
- Prefer solutions that already account for scale and operations (not
  just "the code works"), given a background working with high-volume
  platforms
- Development environment: Distrobox containers isolated per project,
  each with its own home — don't assume dotfiles/config come from the
  "outside" system; assume the environment is already set up the way
  it's configured

## Assistance premises (how I expect the AI to work with me)

- **No vibe coding in production.** A suggestion accepted without
  understanding the logic behind it is not acceptable for
  production-bound code. If the AI proposes something non-trivial, it
  explains the "why," not just the "what."
- **Small, reviewable diffs.** Prefer surgical, incremental changes over
  large rewrites — I need to be able to review line by line in
  reasonable time. If a task requires a large change, break it into
  verifiable steps.
- **AI is good for bulk/boilerplate, not architectural decisions.**
  Repetitive code generation, tests, documentation, mechanical
  refactors: good use of AI. Architecture decisions, scale trade-offs,
  data modeling in payment systems: the AI's proposal is input, not the
  decision — the final call is mine.
- **Verify against reality, not plausibility.** "Looks right" from an
  LLM is not a criterion. Test it, run it, check it against real
  observability before considering something resolved.
- **Explicit context over implicit assumption.** Already a convention
  in project-level CLAUDE.md files (e.g., don't assume dotfiles come
  from the "outside" system in Distrobox containers) — this applies
  generally: when context is missing, ask, don't assume.
- **Plan before executing on non-trivial tasks.** For anything beyond a
  one-liner, show the plan before touching code (e.g., plan mode) rather
  than jumping straight to a diff. The plan is what gets reviewed first
  — the diff comes after.
- **Repeated workflows become slash commands, not re-explained prompts.**
  If a flow recurs (reviewing a PR against a project's coding
  guidelines, generating a changelog, etc.), it belongs in
  `.claude/commands/`, not retyped each session.
- **Subagents are for parallel exploration, not for final decisions.**
  Fanning out subagents to research or investigate a codebase in
  parallel is fine and encouraged. The architectural call at the end is
  still mine — same rule as "AI is good for bulk/boilerplate, not
  architectural decisions" above, applied to multi-agent work
  specifically.
- **Hooks are guardrails, not a substitute for review.** Hooks (e.g.
  blocking destructive commands) are welcome as an automatic safety net,
  but they don't replace me actually reading the diff.
- **Checkpoint via git before large changes.** Before a session that
  will touch multiple parts of the codebase, commit or at least `git
  stash` first. Reverting should never depend solely on catching a bad
  diff in real time.
- **Clear context between unrelated tasks.** Don't let context grow
  indefinitely across unrelated work — long context degrades response
  quality and wastes tokens. Clear (`/clear`) between unrelated tasks
  and reintroduce only what's relevant. This matters even more with
  `context-mode`/`rtk` in the loop, since their session-continuity and
  compression behavior assumes context is being managed deliberately,
  not left to grow by default.

## About this file
This is **global** context (via dotfiles, the same across every
environment/project). Project-specific instructions go in that repo's
own CLAUDE.md, not here.

@RTK.md
