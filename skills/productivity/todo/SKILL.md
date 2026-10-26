---
name: todo
description: Capture, prioritise and link ad-hoc work asks (review a PR, design a feature, message someone) in Taskwarrior. Use when the user says "note this down", "track this", "add a todo", "remind me to", "what's on my plate", "reprioritise my todos", or otherwise asks to record or reorganise untracked tasks.
---

# todo

The user's ad-hoc asks live in Taskwarrior. Claude writes and organises tasks; the user views them in `taskwarrior-tui` and marks them done there (`d`).

## First use in a session

Run `bash <this skill's base directory>/check-deps.sh` once before any `task` command. It installs `task` and `taskwarrior-tui` via Homebrew if missing and creates `~/.taskrc`. Stop and report if it fails.

Always pass `rc.confirmation=off` on `modify`, `delete` and `done` so commands never block on a prompt.

## Capturing a task

1. Check for duplicates: `task status:pending export`. If an existing task covers the same ask, annotate or modify it instead of adding a new one.
2. Add it:

   ```
   task rc.verbose=new-id add "<verb-first description, include the person>" priority:<H|M|L> +<tag> [project:<name>] [due:<date>] [depends:<id,id>]
   ```

3. Attach links or context: `task <id> annotate "<PR URL / Slack link / note>"`.
4. Reply with one line: ID, description, priority, dependencies.

Descriptions start with a verb and name the person: `Review Raj's PR #412 (auth refactor)`, `Message Priya about Q4 capacity`.

**Tags** (one primary): `+review`, `+design`, `+message`, `+followup`, `+fix`, `+meeting`, `+read`. Use `project:` when the ask belongs to a known feature or repo.

**Priority:**

- `H`: someone is blocked on the user, it is due today or tomorrow, or a lead/exec asked.
- `M`: due this week, or no signal either way (default).
- `L`: nice to have, no one waiting.

**Due dates:** set only when the user states or clearly implies one (`due:tomorrow`, `due:friday`, `due:2026-11-03`). Do not invent deadlines.

**Dependencies:** add `depends:<id>` when this task cannot start until another pending task is done (e.g. "message Priya once the design is ready" depends on the design task). Look up IDs from the pending export.

Capture several asks in one message as separate tasks, then link them.

## Reviewing and reprioritising

- "What's on my plate": `task rc.verbose=nothing next` and summarise the top items, calling out overdue and blocked tasks.
- "Reprioritise": read `task status:pending export`, re-apply the priority rules above using due dates, age and who is waiting, then `task rc.confirmation=off <id> modify priority:<X>` and fix stale `depends`. Report what changed.
- Done/remove only when the user asks: `task rc.confirmation=off <id> done` or `delete`.

## Viewing

The user opens `taskwarrior-tui` (aliased `todo`; `todon` prints `task next`). Keys: `d` done, `a` add, `e` edit, `m` modify, `/` filter, `q` quit.
