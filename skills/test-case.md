---
name: test-case
description: Generate manual QA test cases from a code diff or GitHub PR. Usage: /test-case [PR_URL]
---

# Generate Manual Test Cases

You are generating manual QA test cases from a code diff. Follow every step below exactly.

## Step 1: Resolve the Diff

Run the bash commands below to get the code diff. Follow the resolution order strictly.

**Check for PR URL argument:**
If `args` contains a URL starting with `https://github.com`, run:
```bash
gh pr diff <URL_FROM_ARGS>
```
If `gh` is not installed, stop and say:
> GitHub CLI (`gh`) is required for PR diffs. Install it from https://cli.github.com

If the `gh` command fails, stop and say:
> Could not fetch PR diff. Make sure you are authenticated: run `gh auth login`

**If no PR URL was provided, check for uncommitted local changes:**
```bash
git diff HEAD
```
If this produces output, use it as the diff.

**If `git diff HEAD` is empty, compare current branch to base:**
```bash
git diff origin/main...HEAD 2>/dev/null || git diff origin/master...HEAD 2>/dev/null
```
Use the output as the diff.

**If all of the above produce no output, stop and say:**
> No changes detected. Stage some changes, commit to a branch, or pass a GitHub PR URL: `/test-case https://github.com/owner/repo/pull/123`

## Step 2: Determine Output Filename

Run these commands to determine the output filename (use the first one that returns a non-empty value):

```bash
git branch --show-current
```

If empty:
```bash
date +%Y-%m-%d
```

Sanitize the result: replace any character that is not a letter, number, or hyphen with a hyphen. Lowercase it. This is `{name}`.

The output path is: `./test-cases/{name}.html`

## Step 3: Get Project Context

```bash
basename $(git rev-parse --show-toplevel 2>/dev/null) 2>/dev/null || basename "$PWD"
```

This is `{project_name}`. Also note `{name}` (branch/date) and today's date as `{date}`.

## Step 3b: Read Recent Claude Code Chat History (Optional Context)

This step adds context about WHY the code changed, not just what changed. It is optional — if it fails at any point, skip it silently and continue.

Run these commands to find and read the most recent Claude Code conversation for this project:

```bash
# Convert the current git repo path to Claude's encoded project key
# e.g. /Users/alice/myproject → -Users-alice-myproject
PROJECT_PATH=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
ENCODED=$(echo "$PROJECT_PATH" | sed 's|^/||; s|/|-|g')
CLAUDE_DIR="$HOME/.claude/projects/$ENCODED"

# Find the most recently modified JSONL session file
LATEST_SESSION=$(ls -t "$CLAUDE_DIR"/*.jsonl 2>/dev/null | head -1)
echo "$LATEST_SESSION"
```

If `$LATEST_SESSION` is non-empty, run:

```bash
# Extract the last 60 user messages from the session
python3 -c "
import json, sys
msgs = []
with open('$LATEST_SESSION') as f:
    for line in f:
        try:
            obj = json.loads(line)
            msg = obj.get('message', {})
            if msg.get('role') == 'user':
                content = msg.get('content', '')
                if isinstance(content, list):
                    for c in content:
                        if isinstance(c, dict) and c.get('type') == 'text':
                            msgs.append(c['text'])
                elif isinstance(content, str) and content.strip():
                    msgs.append(content)
        except: pass
for m in msgs[-60:]:
    print('USER:', m[:300])
    print('---')
"
```

Read this output. Use it as background context when generating test cases — it tells you what the developer was trying to build, what problems they were solving, and what decisions were made. Do NOT include the raw chat text in the HTML output. Only use it to write better, more informed test cases.

## Step 4: Analyze the Diff and Generate Test Cases

Carefully read the diff. For every meaningful change (new function, modified logic, changed UI, new API endpoint, config change, etc.), generate test cases.

Group all test cases into these 4 categories:

**Happy Path** — the intended new behavior works correctly
**Edge Cases** — boundary inputs, empty states, null/undefined values, max lengths
**Regression** — existing behavior that the change could accidentally break
**Negative** — inputs or actions that should fail, be blocked, or return errors

For each test case, produce:
- `id`: sequential string like `TC-001`, `TC-002`, etc. (global across all categories)
- `category`: one of `Happy Path`, `Edge Cases`, `Regression`, `Negative`
- `description`: one sentence describing what is being tested
- `preconditions`: what must be true before the test starts (e.g., "User is logged in", "Database has 0 records")
- `priority`: `High`, `Medium`, or `Low`
  - High = core functionality, data integrity, security, authentication
  - Medium = important UX flows, validation, error messages
  - Low = cosmetic, edge-of-edge, very unlikely scenarios
- `steps`: numbered list of concrete user actions (what to click, type, navigate to)
- `expected_result`: the exact observable outcome that confirms the test passed

Keep steps concrete and specific: "Click the Submit button" not "Submit the form".
Reference actual field names, button labels, and routes from the diff where visible.

Hold this data in your context — you will embed it directly into HTML in the next step.

## Step 5: Generate the HTML File Content

Using the test cases from Step 4, write a complete self-contained HTML file. Use the exact template below, substituting all `{{PLACEHOLDER}}` values with real data.

- Replace `{{PROJECT_NAME}}` with `{project_name}`
- Replace `{{BRANCH_OR_PR}}` with `{name}`
- Replace `{{DATE}}` with `{date}`
- Replace `{{TOTAL_COUNT}}` with total number of test cases
- Replace `{{HIGH_COUNT}}`, `{{MEDIUM_COUNT}}`, `{{LOW_COUNT}}` with counts by priority
- Replace `{{HAPPY_COUNT}}`, `{{EDGE_COUNT}}`, `{{REGRESSION_COUNT}}`, `{{NEGATIVE_COUNT}}` with counts by category
- Replace `{{TEST_CASE_ROWS}}` with generated HTML rows (see format below)
- Replace `{{CATEGORY_SECTIONS}}` with grouped test case sections (see format below)

**Row format** (one per test case, for the summary table):
```html
<tr>
  <td class="tc-id">TC-001</td>
  <td>Description of the test case</td>
  <td>User is logged in</td>
  <td><span class="badge badge-high">High</span></td>
  <td><span class="category-tag">Happy Path</span></td>
  <td><button class="expand-btn" onclick="toggleDetail('TC-001')">▶ Steps</button></td>
</tr>
<tr id="detail-TC-001" class="detail-row" style="display:none">
  <td colspan="6">
    <div class="detail-content">
      <strong>Steps:</strong>
      <ol>
        <li>Step one</li>
        <li>Step two</li>
      </ol>
      <strong>Expected Result:</strong>
      <p>The exact observable outcome</p>
    </div>
  </td>
</tr>
```

**Category section format** (one section per category that has test cases):
```html
<section class="category-section">
  <h2 class="category-heading">Happy Path</h2>
  <table>
    <thead>
      <tr><th>ID</th><th>Description</th><th>Preconditions</th><th>Priority</th><th>Category</th><th></th></tr>
    </thead>
    <tbody>
      <!-- repeat row format above for each test case in this category -->
    </tbody>
  </table>
</section>
```

**Full HTML template:**

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Test Cases — {{PROJECT_NAME}}</title>
<style>
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; font-size: 14px; color: #1a1a2e; background: #f8f9fa; padding: 24px; }
  .header { background: #1a1a2e; color: #fff; border-radius: 10px; padding: 24px 32px; margin-bottom: 20px; }
  .header h1 { font-size: 22px; font-weight: 700; margin-bottom: 6px; }
  .header .meta { font-size: 13px; color: #a0aec0; display: flex; gap: 24px; flex-wrap: wrap; }
  .summary-bar { display: flex; gap: 12px; margin-bottom: 24px; flex-wrap: wrap; }
  .summary-card { background: #fff; border-radius: 8px; padding: 14px 20px; border: 1px solid #e2e8f0; flex: 1; min-width: 120px; text-align: center; }
  .summary-card .label { font-size: 11px; color: #718096; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 6px; }
  .summary-card .value { font-size: 26px; font-weight: 700; color: #1a1a2e; }
  .summary-card.high .value { color: #e53e3e; }
  .summary-card.medium .value { color: #d69e2e; }
  .summary-card.low .value { color: #718096; }
  .category-section { margin-bottom: 32px; }
  .category-heading { font-size: 16px; font-weight: 700; color: #1a1a2e; margin-bottom: 12px; padding-left: 4px; border-left: 4px solid #667eea; padding-left: 12px; }
  table { width: 100%; border-collapse: collapse; background: #fff; border-radius: 8px; overflow: hidden; border: 1px solid #e2e8f0; }
  th { background: #f7fafc; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; color: #718096; padding: 10px 14px; text-align: left; border-bottom: 1px solid #e2e8f0; }
  td { padding: 12px 14px; border-bottom: 1px solid #f0f4f8; vertical-align: top; }
  tr:last-child td { border-bottom: none; }
  tr:hover td { background: #f7fafc; }
  .tc-id { font-family: monospace; font-weight: 700; color: #667eea; white-space: nowrap; }
  .badge { display: inline-block; padding: 2px 8px; border-radius: 4px; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.4px; }
  .badge-high { background: #fff5f5; color: #e53e3e; border: 1px solid #fed7d7; }
  .badge-medium { background: #fffff0; color: #d69e2e; border: 1px solid #fefcbf; }
  .badge-low { background: #f7fafc; color: #718096; border: 1px solid #e2e8f0; }
  .category-tag { font-size: 11px; color: #667eea; background: #ebf4ff; padding: 2px 8px; border-radius: 4px; white-space: nowrap; }
  .expand-btn { background: none; border: 1px solid #e2e8f0; border-radius: 4px; padding: 4px 10px; cursor: pointer; font-size: 12px; color: #667eea; white-space: nowrap; }
  .expand-btn:hover { background: #ebf4ff; }
  .detail-row td { background: #f7fafc; padding: 16px 20px; }
  .detail-content { max-width: 700px; }
  .detail-content ol { margin: 8px 0 16px 20px; }
  .detail-content li { margin-bottom: 6px; line-height: 1.5; }
  .detail-content p { margin-top: 6px; color: #4a5568; line-height: 1.5; }
  @media print {
    body { background: #fff; padding: 0; }
    .expand-btn { display: none; }
    .detail-row { display: table-row !important; }
    .detail-row td { display: table-cell !important; }
  }
</style>
</head>
<body>
<div class="header">
  <h1>Manual Test Cases — {{PROJECT_NAME}}</h1>
  <div class="meta">
    <span>Branch / PR: {{BRANCH_OR_PR}}</span>
    <span>Generated: {{DATE}}</span>
    <span>Total: {{TOTAL_COUNT}} test cases</span>
  </div>
</div>
<div class="summary-bar">
  <div class="summary-card high"><div class="label">High</div><div class="value">{{HIGH_COUNT}}</div></div>
  <div class="summary-card medium"><div class="label">Medium</div><div class="value">{{MEDIUM_COUNT}}</div></div>
  <div class="summary-card low"><div class="label">Low</div><div class="value">{{LOW_COUNT}}</div></div>
  <div class="summary-card"><div class="label">Happy Path</div><div class="value">{{HAPPY_COUNT}}</div></div>
  <div class="summary-card"><div class="label">Edge Cases</div><div class="value">{{EDGE_COUNT}}</div></div>
  <div class="summary-card"><div class="label">Regression</div><div class="value">{{REGRESSION_COUNT}}</div></div>
  <div class="summary-card"><div class="label">Negative</div><div class="value">{{NEGATIVE_COUNT}}</div></div>
</div>
{{CATEGORY_SECTIONS}}
<script>
function toggleDetail(id) {
  var row = document.getElementById('detail-' + id);
  var btn = document.querySelector('[onclick="toggleDetail(\'' + id + '\')"]');
  if (row.style.display === 'none') {
    row.style.display = 'table-row';
    btn.textContent = '▼ Steps';
  } else {
    row.style.display = 'none';
    btn.textContent = '▶ Steps';
  }
}
</script>
</body>
</html>
```

## Step 6: Save the File

Run:
```bash
mkdir -p ./test-cases
```

Then write the complete HTML you generated in Step 5 to the file `./test-cases/{name}.html`. Use the Write tool (not echo/cat) to write the file.

## Step 7: Confirm

After saving, print exactly this format (substituting real values):
```
✓ Test cases saved to: ./test-cases/{name}.html
  Total: {TOTAL_COUNT} test cases  ({HIGH_COUNT} High · {MEDIUM_COUNT} Medium · {LOW_COUNT} Low)
  Categories: {HAPPY_COUNT} Happy Path · {EDGE_COUNT} Edge Cases · {REGRESSION_COUNT} Regression · {NEGATIVE_COUNT} Negative
```
