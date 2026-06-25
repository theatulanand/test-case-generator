# Test Case Generator — Claude Code Plugin Design

**Date:** 2026-06-25  
**Status:** Approved

---

## Overview

A Claude Code skill that generates manual QA test cases from a code diff. Triggered by `/test-case` in any Claude Code session. Output is a self-contained HTML file saved to `test-cases/{name}.html` in the project root.

---

## Trigger & Arguments

```
/test-case                          # auto-detect diff
/test-case https://github.com/...   # use GitHub PR diff
```

The skill is installed as a single markdown file at:
`~/.claude/plugins/test-case-generator/skills/test-case.md`

---

## Diff Resolution (in order)

1. **PR URL passed as args** → `gh pr diff <url>`
2. **Uncommitted local changes** → `git diff HEAD`
3. **Current branch vs base (committed to remote)** → `git diff origin/main...HEAD` (falls back to `origin/master`)
4. **No diff found** → exit with message: "No changes detected. Commit your changes or pass a PR URL."

---

## Test Case Generation

Claude analyzes the diff and generates test cases grouped into 4 categories:

| Category | Description |
|----------|-------------|
| Happy Path | Intended new behavior works correctly |
| Edge Cases | Boundary inputs, empty states, null values |
| Regression | Existing behavior the change could break |
| Negative | What should fail or be blocked |

Each test case has two layers:

**Table row:**
- Test ID (TC-001, TC-002, ...)
- Description
- Preconditions
- Priority (High / Medium / Low)

**Expandable detail (click to reveal):**
- Numbered steps
- Expected Result

---

## HTML Output

### File Path

Saved to `./test-cases/{name}.html` in the project root, where `{name}` resolves via:
1. Claude Code chat/session name (from `~/.claude/projects/<path>/.last-session` or equivalent)
2. Current git branch name (e.g., `feature-auth-login`)
3. Today's date (e.g., `2026-06-25`)

### HTML Structure

- Self-contained (no external CDN dependencies, all CSS/JS inline)
- **Header:** project name, branch/PR name, generation date, total test count
- **Summary bar:** counts by priority (High / Medium / Low) and by category
- **Test case tables:** grouped by category
- **Expandable rows:** click to reveal full steps + expected result
- **Priority badges:** color-coded (red = High, yellow = Medium, gray = Low)
- **Print-friendly CSS:** QA can print directly to PDF

### Confirmation

After saving, the skill prints:
```
Test cases saved to: ./test-cases/feature-auth-login.html
Total: 12 test cases (4 High, 5 Medium, 3 Low)
```

---

## Authentication

Uses Claude Code's existing logged-in session. No separate API key required.

---

## Dependencies

- `git` — required for all diff modes
- `gh` CLI (GitHub CLI) — required only when a PR URL is passed; if not installed, the skill exits with: "GitHub CLI (`gh`) is required for PR diffs. Install it from https://cli.github.com"

---

## Out of Scope

- No VS Code extension (pure Claude Code skill)
- No intermediate JSON output — Claude generates HTML directly
- No automatic test execution — manual QA use only
- No MCP server or Node.js dependencies
