# test-case-generator

A Claude Code slash command that generates manual QA test cases from your code diff and Claude chat history, saved as a self-contained HTML file.

## Install

```bash
bash install.sh
```

Then restart Claude Code.

## Usage

```
/test-case                                        # auto-detects local diff or branch vs origin
/test-case https://github.com/owner/repo/pull/123 # uses a GitHub PR diff
```

Output is saved to `./test-cases/<branch-name>.html` in your project.

## How it works

1. **Gets the diff** — PR URL → local uncommitted changes → current branch vs `origin/main`
2. **Reads your Claude Code chat history** — finds the most recent conversation for this project and uses it as context to understand *why* the code changed, not just *what* changed. Better context = more accurate, relevant test cases.
3. **Generates test cases** — grouped into 6 categories (see below)
4. **Saves HTML** — to `./test-cases/<branch-name>.html`

## What it generates

Test cases grouped into 6 categories:

| Category | Description |
|---|---|
| **Bare Minimum** | 2–5 must-pass tests — if these fail, the feature is broken |
| **Happy Path** | Intended new behavior works correctly |
| **Edge Cases** | Boundary inputs, empty states, null values |
| **Regression** | Existing behavior the change could accidentally break |
| **Negative** | What should fail or be blocked |
| **Affected Legacy** | Older/unrelated flows that could silently break |

Each test case includes: ID, description, preconditions, priority (High/Medium/Low), numbered steps, and expected result.

## HTML output

- Self-contained (no external dependencies)
- Expandable rows — click to reveal steps
- Color-coded priority badges
- Print to PDF friendly

## Requirements

- `git` — required for all diff modes
- `gh` CLI — required only when passing a PR URL (`brew install gh`)

## Re-deploy after edits

Edit `commands/test-case.md` then run:

```bash
bash install.sh
```
