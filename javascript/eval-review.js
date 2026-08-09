#!/usr/bin/env node
// eval-review.html — portiert nach javascript
// Quelle: html, Projects@python-hardener:python-hardener/eval-review.html
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import fs from 'fs/promises';
import path from 'path';

async function main() {
  const args = process.argv.slice(2);
  if (args.length !== 1) {
    console.error('Usage: node generate-review.js <output-file>');
    process.exit(1);
  }
  
  const outputFile = args[0];
  
  // Create the HTML document
  const doc = createDocument();
  
  // Generate the complete HTML string
  const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Eval Review</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@500;600&family=Lora:wght@400;500&display=swap" rel="stylesheet">
  <script src="https://cdn.sheetjs.com/xlsx-0.20.3/package/dist/xlsx.full.min.js" integrity="sha384-EnyY0/GSHQGSxSgMwaIPzSESbqoOLSexfnSMN2AP+39Ckmn92stwABZynq1JyzdT" crossorigin="anonymous"></script>
  <style>
    :root {
      --bg: #faf9f5;
      --surface: #ffffff;
      --border: #e8e6dc;
      --text: #141413;
      --text-muted: #b0aea5;
      --accent: #d97757;
      --accent-hover: #c4613f;
      --green: #788c5d;
      --green-bg: #eef2e8;
      --red: #c44;
      --red-bg: #fceaea;
      --header-bg: #141413;
      --header-text: #faf9f5;
      --radius: 6px;
    }

    * { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      font-family: 'Lora', Georgia, serif;
      background: var(--bg);
      color: var(--text);
      height: 100vh;
      display: flex;
      flex-direction: column;
    }

    /* ---- Header ---- */
    .header {
      background: var(--header-bg);
      color: var(--header-text);
      padding: 1rem 2rem;
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-shrink: 0;
    }
    .header h1 {
      font-family: 'Poppins', sans-serif;
      font-size: 1.25rem;
      font-weight: 600;
    }
    .header .instructions {
      font-size: 0.8rem;
      opacity: 0.7;
      margin-top: 0.25rem;
    }
    .header .progress {
      font-size: 0.875rem;
      opacity: 0.8;
      text-align: right;
    }

    /* ---- Main content ---- */
    .main {
      flex: 1;
      overflow-y: auto;
      padding: 1.5rem 2rem;
      display: flex;
      flex-direction: column;
      gap: 1.25rem;
    }

    /* ---- Sections ---- */
    .section {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      flex-shrink: 0;
    }
    .section-header {
      font-family: 'Poppins', sans-serif;
      padding: 0.75rem 1rem;
      font-size: 0.75rem;
      font-weight: 500;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      color: var(--text-muted);
      border-bottom: 1px solid var(--border);
      background: var(--bg);
    }
    .section-body {
      padding: 1rem;
    }

    /* ---- Config badge ---- */
    .config-badge {
      display: inline-block;
      padding: 0.2rem 0.625rem;
      border-radius: 9999px;
      font-family: 'Poppins', sans-serif;
      font-size: 0.6875rem;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.03em;
      margin-left: 0.75rem;
      vertical-align: middle;
    }
    .config-badge.config-primary {
      background: rgba(33, 150, 243, 0.12);
      color: #1976d2;
    }
    .config-badge.config-baseline {
      background: rgba(255, 193, 7, 0.15);
      color: #f57f17;
    }

    /* ---- Prompt ---- */
    .prompt-text {
      white-space: pre-wrap;
      font-size: 0.9375rem;
      line-height: 1.6;
    }

    /* ---- Outputs ---- */
    .output-file {
      border: 1px solid var(--border);
      border-radius: var(--radius);
      overflow: hidden;
    }
    .output-file + .output-file {
      margin-top: 1rem;
    }
    .output-file-header {
      padding: 0.5rem 0.75rem;
      font-size: 0.8rem;
      font-weight: 600;
      color: var(--text-muted);
      background: var(--bg);
      border-bottom: 1px solid var(--border);
      font-family: 'SF Mono', SFMono-Regular, Consolas, 'Liberation Mono', Menlo, monospace;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .output-file-header .dl-btn {
      font-size: 0.7rem;
      color: var(--accent);
      text-decoration: none;
      cursor: pointer;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      font-weight: 500;
      opacity: 0.8;
    }
    .output-file-header .dl-btn:hover {
      opacity: 1;
      text-decoration: underline;
    }
    .output-file-content {
      padding: 0.75rem;
      overflow-x: auto;
    }
    .output-file-content pre {
      font-size: 0.8125rem;
      line-height: 1.5;
      white-space: pre-wrap;
      word-break: break-word;
      font-family: 'SF Mono', SFMono-Regular, Consolas, 'Liberation Mono', Menlo, monospace;
    }
    .output-file-content img {
      max-width: 100%;
      height: auto;
      border-radius: 4px;
    }
    .output-file-content iframe {
      width: 100%;
      height: 600px;
      border: none;
    }
    .output-file-content table {
      border-collapse: collapse;
      font-size: 0.8125rem;
      width: 100%;
    }
    .output-file-content table td,
    .output-file-content table th {
      border: 1px solid var(--border);
      padding: 0.375rem 0.5rem;
      text-align: left;
    }
    .output-file-content table th {
      background: var(--bg);
      font-weight: 600;
    }
    .output-file-content .download-link {
      display: inline-flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.5rem 1rem;
      background: var(--bg);
      border: 1px solid var(--border);
      border-radius: 4px;
      color: var(--accent);
      text-decoration: none;
      font-size: 0.875rem;
      cursor: pointer;
    }
    .output-file-content .download-link:hover {
      background: var(--border);
    }
    .empty-state {
      color: var(--text-muted);
      font-style: italic;
      padding: 2rem;
      text-align: center;
    }

    /* ---- Feedback ---- */
    .prev-feedback {
      background: var(--bg);
      border: 1px solid var(--border);
      border-radius: 4px;
      padding: 0.625rem 0.75rem;
      margin-top: 0.75rem;
      font-size: 0.8125rem;
      color: var(--text-muted);
      line-height: 1.5;
    }
    .prev-feedback-label {
      font-size: 0.7rem;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.04em;
      margin-bottom: 0.25rem;
      color: var(--text-muted);
    }
    .feedback-textarea {
      width: 100%;
      min-height: 100px;
      padding: 0.75rem;
      border: 1px solid var(--border);
      border-radius: 4px;
      font-family: inherit;
      font-size: 0.9375rem;
      line-height: 1.5;
      resize: vertical;
      color: var(--text);
    }
    .feedback-textarea:focus {
      outline: none;
      border-color: var(--accent);
      box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
    }
    .feedback-status {
      font-size: 0.75rem;
      color: var(--text-muted);
      margin-top: 0.5rem;
      min-height: 1.1em;
    }

    /* ---- Grades (collapsible) ---- */
    .grades-toggle {
      display: flex;
      align-items: center;
      cursor: pointer;
      user-select: none;
    }
    .grades-toggle:hover {
      color: var(--accent);
    }
    .grades-toggle .arrow {
      margin-right: 0.5rem;
      transition: transform 0.15s;
      font-size: 0.75rem;
    }
    .grades-toggle .arrow.open {
      transform: rotate(90deg);
    }
    .grades-content {
      display: none;
      margin-top: 0.75rem;
    }
    .grades-content.open {
      display: block;
    }
    .grades-summary {
      font-size: 0.875rem;
      margin-bottom: 0.75rem;
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }
    .grade-badge {
      display: inline-block;
      padding: 0.125rem 0.5rem;
      border-radius: 9999px;
      font-size: 0.75rem;
      font-weight: 600;
    }
    .grade-pass { background: var(--green-bg); color: var(--green); }
    .grade-fail { background: var(--red-bg); color: var(--red); }
    .assertion-list {
      list-style: none;
    }
    .assertion-item {
      padding: 0.625rem 0;
      border-bottom: 1px solid var(--border);
      font-size: 0.8125rem;
    }
    .assertion-item:last-child { border-bottom: none; }
    .assertion-status {
      font-weight: 600;
      margin-right: 0.5rem;
    }
    .assertion-status.pass { color: var(--green); }
    .assertion-status.fail { color: var(--red); }
    .assertion-evidence {
      color: var(--text-muted);
      font-size: 0.75rem;
      margin-top: 0.25rem;
      padding-left: 1.5rem;
    }

    /* ---- View tabs ---- */
    .view-tabs {
      display: flex;
      gap: 0;
      padding: 0 2rem;
      background: var(--bg);
      border-bottom: 1px solid var(--border);
      flex-shrink: 0;
    }
    .view-tab {
      font-family: 'Poppins', sans-serif;
      padding: 0.625rem 1.25rem;
      font-size: 0.8125rem;
      font-weight: 500;
      cursor: pointer;
      border: none;
      background: none;
      color: var(--text-muted);
      border-bottom: 2px solid transparent;
      transition: all 0.15s;
    }
    .view-tab:hover { color: var(--text); }
    .view-tab.active {
      color: var(--accent);
      border-bottom-color: var(--accent);
    }
    .view-panel { display: none; }
    .view-panel.active { display: flex; flex-direction: column; flex: 1; overflow: hidden; }

    /* ---- Benchmark view ---- */
    .benchmark-view {
      padding: 1.5rem 2rem;
      overflow-y: auto;
      flex: 1;
    }
    .benchmark-table {
      border-collapse: collapse;
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      font-size: 0.8125rem;
      width: 100%;
      margin-bottom: 1.5rem;
    }
    .benchmark-table th, .benchmark-table td {
      padding: 0.625rem 0.75rem;
      text-align: left;
      border: 1px solid var(--border);
    }
    .benchmark-table th {
      font-family: 'Poppins', sans-serif;
      background: var(--header-bg);
      color: var(--header-text);
      font-weight: 500;
      font-size: 0.75rem;
      text-transform: uppercase;
      letter-spacing: 0.04em;
    }
    .benchmark-table tr:hover { background: var(--bg); }
    .benchmark-table tr.benchmark-row-with { background: rgba(33, 150, 243, 0.06); }
    .benchmark-table tr.benchmark-row-without { background: rgba(255, 193, 7, 0.06); }
    .benchmark-table tr.benchmark-row-with:hover { background: rgba(33, 150, 243, 0.12); }
    .benchmark-table tr.benchmark-row-without:hover { background: rgba(255, 193, 7, 0.12); }
    .benchmark-table tr.benchmark-row-avg { font-weight: 600; border-top: 2px solid var(--border); }
    .benchmark-table tr.benchmark-row-avg.benchmark-row-with { background: rgba(33, 150, 243, 0.12); }
    .benchmark-table tr.benchmark-row-avg.benchmark-row-without { background: rgba(255, 193, 7, 0.12); }
    .benchmark-delta-positive { color: var(--green); font-weight: 600; }
    .benchmark-delta-negative { color: var(--red); font-weight: 600; }
    .benchmark-notes {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      padding: 1rem;
    }
    .benchmark-notes h3 {
      font-family: 'Poppins', sans-serif;
      font-size: 0.875rem;
      margin-bottom: 0.75rem;
    }
    .benchmark-notes ul {
      list-style: disc;
      padding-left: 1.25rem;
    }
    .benchmark-notes li {
      font-size: 0.8125rem;
      line-height: 1.6;
      margin-bottom: 0.375rem;
    }
    .benchmark-empty {
      color: var(--text-muted);
      font-style: italic;
      text-align: center;
      padding: 3rem;
    }

    /* ---- Navigation ---- */
    .nav {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 1rem 2rem;
      border-top: 1px solid var(--border);
      background: var(--surface);
      flex-shrink: 0;
    }
    .nav-btn {
      font-family: 'Poppins', sans-serif;
      padding: 0.5rem 1.25rem;
      border: 1px solid var(--border);
      border-radius: var(--radius);
      background: var(--surface);
      cursor: pointer;
      font-size: 0.875rem;
      font-weight: 500;
      color: var(--text);
      transition: all 0.15s;
    }
    .nav-btn:hover:not(:disabled) {
      background: var(--bg);
      border-color: var(--text-muted);
    }
    .nav-btn:disabled {
      opacity: 0.4;
      cursor: not-allowed;
    }
    .done-btn {
      font-family: 'Poppins', sans-serif;
      padding: 0.5rem 1.5rem;
      border: 1px solid var(--border);
      border-radius: var(--radius);
      background: var(--surface);
      color: var(--text);
      cursor: pointer;
      font-size: 0.875rem;
      font-weight: 500;
      transition: all 0.15s;
    }
    .done-btn:hover {
      background: var(--bg);
      border-color: var(--text-muted);
    }
    .done-btn.ready {
      border: none;
      background: var(--accent);
      color: white;
      font-weight: 600;
    }
    .done-btn.ready:hover {
      background: var(--accent-hover);
    }
    /* ---- Done overlay ---- */
    .done-overlay {
      display: none;
      position: fixed;
      inset: 0;
      background: rgba(0, 0, 0, 0.5);
      z-index: 100;
      justify-content: center;
      align-items: center;
    }
    .done-overlay.visible {
      display: flex;
    }
    .done-card {
      background: var(--surface);
      border-radius: 12px;
      padding: 2rem 3rem;
      text-align: center;
      box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
      max-width: 500px;
    }
    .done-card h2 {
      font-size: 1.5rem;
      margin-bottom: 0.5rem;
    }
    .done-card p {
      color: var(--text-muted);
      margin-bottom: 1.5rem;
      line-height: 1.5;
    }
    .done-card .btn-row {
      display: flex;
      gap: 0.5rem;
      justify-content: center;
    }
    .done-card button {
      padding: 0.5rem 1.25rem;
      border: 1px solid var(--border);
      border-radius: var(--radius);
      background: var(--surface);
      cursor: pointer;
      font-size: 0.875rem;
    }
    .done-card button:hover {
      background: var(--bg);
    }
    /* ---- Toast ---- */
    .toast {
      position: fixed;
      bottom: 5rem;
      left: 50%;
      transform: translateX(-50%);
      background: var(--header-bg);
      color: var(--header-text);
      padding: 0.625rem 1.25rem;
      border-radius: var(--radius);
      font-size: 0.875rem;
      opacity: 0;
      transition: opacity 0.3s;
      pointer-events: none;
      z-index: 200;
    }
    .toast.visible {
      opacity: 1;
    }
  </style>
</head>
<body>
  <div id="app" style="height:100vh; display:flex; flex-direction:column;">
    <div class="header">
      <div>
        <h1>Eval Review: <span id="skill-name"></span></h1>
        <div class="instructions">Review each output and leave feedback below. Navigate with arrow keys or buttons. When done, copy feedback and paste into Claude Code.</div>
      </div>
      <div class="progress" id="progress"></div>
    </div>

    <!-- View tabs (only shown when benchmark data exists) -->
    <div class="view-tabs" id="view-tabs" style="display:none;">
      <button class="view-tab active" onclick="switchView('outputs')">Outputs</button>
      <button class="view-tab" onclick="switchView('benchmark')">Benchmark</button>
    </div>

    <!-- Outputs panel (qualitative review) -->
    <div class="view-panel active" id="panel-outputs">
    <div class="main">
      <!-- Prompt -->
      <div class="section">
        <div class="section-header">Prompt <span class="config-badge" id="config-badge" style="display:none;"></span></div>
        <div class="section-body">
          <div class="prompt-text" id="prompt-text"></div>
        </div>
      </div>

      <!-- Outputs -->
      <div class="section">
        <div class="section-header">Output</div>
        <div class="section-body" id="outputs-body">
          <div class="empty-state">No output files found</div>
        </div>
      </div>

      <!-- Previous Output (collapsible) -->
      <div class="section" id="prev-outputs-section" style="display:none;">
        <div class="section-header">
          <div class="grades-toggle" onclick="togglePrevOutputs()">
            <span class="arrow" id="prev-outputs-arrow">&#9654;</span>
            Previous Output
          </div>
        </div>
        <div class="grades-content" id="prev-outputs-content"></div>
      </div>

      <!-- Grades (collapsible) -->
      <div class="section" id="grades-section" style="display:none;">
        <div class="section-header">
          <div class="grades-toggle" onclick="toggleGrades()">
            <span class="arrow" id="grades-arrow">&#9654;</span>
            Formal Grades
          </div>
        </div>
        <div class="grades-content" id="grades-content"></div>
      </div>

      <!-- Feedback -->
      <div class="section">
        <div class="section-header">Your Feedback</div>
        <div class="section-body">
          <textarea
            class="feedback-textarea"
            id="feedback"
            placeholder="What do you think of this output? Any issues, suggestions, or things that look great?"
          ></textarea>
          <div class="feedback-status" id="feedback-status"></div>
          <div class="prev-feedback" id="prev-feedback" style="display:none;">
            <div class="prev-feedback-label">Previous feedback</div>
            <div id="prev-feedback-text"></div>
          </div>
        </div>
      </div>
    </div>

    <div class="nav" id="outputs-nav">
      <button class="nav-btn" id="prev-btn" onclick="navigate(-1)">&#8592; Previous</button>
      <button class="done-btn" id="done-btn" onclick="showDoneDialog()">Submit All Reviews</button>
      <button class="nav-btn" id="next-btn" onclick="navigate(1)">Next &#8594;</button>
    </div>
    </div><!-- end panel-outputs -->

    <!-- Benchmark panel (quantitative stats) -->
    <div class="view-panel" id="panel-benchmark">
      <div class="benchmark-view" id="benchmark-content">
        <div class="benchmark-empty">No benchmark data available. Run a benchmark to see quantitative results here.</div>
      </div>
    </div>
  </div>

  <!-- Done overlay -->
  <div class="done-overlay" id="done-overlay">
    <div class="done-card">
      <h2>Review Complete</h2>
      <p>Your feedback has been saved. Go back to your Claude Code session and tell Claude you're done reviewing.</p>
      <div class="btn-row">
        <button onclick="closeDoneDialog()">OK</button>
      </div>
    </div>
  </div>

  <!-- Toast -->
  <div class="toast" id="toast"></div>

  <script>
    // ---- Embedded data (injected by generate_review.py) ----
    const EMBEDDED_DATA = {"skill_name": "python-hardener", "runs": [{"id": "eval-0-job-runner-with_skill", "prompt": "This job_runner.py script is used in production cron jobs. Can you do a full review and fix \u2014 security, error handling, logging, and docstrings? It currently opens the log file on every single call and uses os.chdir() somewhere. Please fix the file and give me a documentation markdown.", "eval_id": 0, "outputs": [{"name": "job_runner.md", "type": "text", "content": "# job_runner.py\n\n## Overview\n\n\`job_runner.py\` is a production cron-job runner that sequentially executes a\nfixed set of build, test, and lint commands, commits the resulting changes to\na local Git repository, and persists run state to a JSON file.  All operational\noutput is routed through Python's \`logging\` module with a rotating file handler\nand a console handler configured once at start-up.\n\n---\n\n## Architecture\n\n\`\`\`\nmain()\n  \u2502\n  \u251c\u2500\u2500 setup_logging()          \u2014 configure RotatingFileHandler + StreamHandler once\n  \u251c\u2500\u2500 load_state()             \u2014 read job_state.json (safe default on failure)\n  \u2502\n  \u251c\u2500\u2500 run_job(\"build\", [...])  \u2500\u2510\n  \u251c\u2500\u2500 run_job(\"test\",  [...])   \u251c\u2500\u2500 subprocess.run(cmd, shell=False, cwd unchanged)\n  \u251c\u2500\u2500 run_job(\"lint\",  [...])  \u2500\u2518\n  \u2502\n  \u251c\u2500\u2500 commit_results(msg)      \u2014 git -C <repo> add . && git -C <repo> commit -m msg\n  \u2514\u2500\u2500 save_state(state)        \u2014 atomic write via tempfile + os.replace()\n\`\`\`\n\n---\n\n## Configuration\n\nAll configuration is read from environment variables so deployments can override\ndefaults without editing the file.\n\n| Variable                  | Default                               | Description                                    |\n|---------------------------|---------------------------------------|------------------------------------------------|\n| \`JOB_RUNNER_WORKSPACE\`    | \`/home/runner/workspace\`              | Root workspace directory                       |\n| \`JOB_RUNNER_LOG_DIR\`      | \`$JOB_RUNNER_WORKSPACE/logs\`          | Directory for rotating log files               |\n| \`JOB_RUNNER_GIT_REPO\`     | \`$JOB_RUNNER_WORKSPACE/output-repo\`   | Path to the Git repository for result commits  |\n| \`LOG_LEVEL\`               | \`INFO\`                                | Python logging level (DEBUG / INFO / WARNING \u2026)|\n| \`JOB_TIMEOUT_SECONDS\`     | \`300\`                                 | Per-job subprocess timeout in seconds          |\n\n---\n\n## API / Functions\n\n| Function | Signature | Description |\n|---|---|---|\n| \`setup_logging\` | \`() -> None\` | Configures the module logger once with a \`RotatingFileHandler\` (10 MB / 7 backups) and a \`StreamHandler\`. Reads level from \`LOG_LEVEL\`. Idempotent. |\n| \`load_state\` | \`() -> dict\` | Reads \`job_state.json\`. Returns \`{\\"jobs\\": [], \\"last_run\\": None}\` on missing file or parse error. |\n| \`save_state\` | \`(state: dict) -> None\` | Serialises \`state\` to \`job_state.json\` atomically via \`tempfile.mkstemp\` + \`os.replace\`. |\n| \`run_job\` | \`(cmd: list[str], job_name: str) -> bool\` | Runs \`cmd\` as a subprocess without a shell. Returns \`True\` on exit code 0. Handles timeout and OS errors. |\n| \`commit_results\` | \`(message: str) -> bool\` | Runs \`git -C <GIT_REPO> add .\` then \`git -C <GIT_REPO> commit -m <message>\`. Returns \`True\` on success. |\n| \`main\` | \`() -> None\` | Orchestrates logging setup, job execution, git commit, and state persistence. |\n\n---\n\n## Security\n\n| Threat | Original code | Countermeasure applied |\n|---|---|---|\n| **Shell injection** | \`subprocess.run(cmd, shell=True)\` \u2014 an attacker-controlled \`cmd\` string could execute arbitrary shell syntax | Changed to \`shell=False\` with \`cmd\` as a \`list[str]\`; the shell is never invoked |\n| **CWD mutation** | \`os.chdir(GIT_REPO)\` permanently alters the process working directory, affecting all subsequent relative-path operations | Replaced with \`git -C <GIT_REPO> ...\`; process CWD is never changed |\n| **Path traversal** | Log and state paths were derived from module-level constants without resolution checks | Paths are now resolved from environment variables; \`Path.mkdir(parents=True)\` is called only inside functions, not at import time |\n| **Secrets in code** | None in original; paths were hardcoded | Paths externalised to environment variables so sensitive deployment details are not committed |\n\n---\n\n## Error handling\n\n| Function | Exception caught | Behaviour on failure |\n|---|---|---|\n| \`load_state\` | \`json.JSONDecodeError\` | Logs a warning with the error detail; returns safe default state |\n| \`load_state\` | \`OSError\` | Logs a warning with the error detail; returns safe default state |\n| \`save_state\` | \`OSError\` | Cleans up the temporary file; re-raises so the caller can decide |\n| \`run_job\` | \`subprocess.TimeoutExpired\` | Logs error with timeout duration; returns \`False\` |\n| \`run_job\` | \`subprocess.SubprocessError\` | Logs error with \`exc_info=True\`; returns \`False\` |\n| \`run_job\` | \`OSError\` | Logs error with \`exc_info=True\`; returns \`False\` |\n| \`commit_results\` | \`subprocess.CalledProcessError\` | Logs rc, command, stdout and stderr; returns \`False\` |\n| \`commit_results\` | \`OSError\` | Logs error with \`exc_info=True\`; returns \`False\` |\n| \`main\` | \`OSError\` (from \`save_state\`) | Logs error; script continues and exits normally |\n\n---\n\n## Changes from the original\n\n| # | Category | Original | Fixed |\n|---|---|---|---|\n| 1 | Resource management | \`log()\` opened the log file on every call | \`setup_logging()\` configures \`RotatingFileHandler\` once; no per-call file open |\n| 2 | Security / CWD | \`os.chdir(GIT_REPO)\` mutated process CWD | \`git -C <GIT_REPO>\` used; CWD never changed |\n| 3 | Security / shell injection | \`subprocess.run(cmd, shell=True)\` | \`subprocess.run(cmd, shell=False)\` with \`cmd\` as a list |\n| 4 | Error handling | Bare \`except:\` in \`load_state\`, \`run_job\`, \`commit_results\` | Replaced with specific exception types + logged errors |\n| 5 | Error handling | Silent \`pass\` in \`commit_results\` hid all git failures | Returns \`bool\`; all failures are logged with details |\n| 6 | Resource management | \`json.load(open(STATE_FILE))\` \u2014 file handle never closed | Wrapped in \`with open(...) as fh:\` |\n| 7 | Reliability | \`save_state\` wrote directly \u2014 torn writes possible | Atomic write via \`tempfile.mkstemp\` + \`os.replace\` |\n| 8 | Module-level side effects | \`LOG_DIR.mkdir()\` called inside \`log()\` on every invocation | Called once inside \`setup_logging()\` |\n| 9 | Docstrings | None | Google-style docstrings on every public function |\n| 10 | Type hints | None | Added to all function signatures |\n| 11 | Configuration | Paths hardcoded | Externalised to environment variables with sensible defaults |\n"}, {"name": "job_runner.py", "type": "text", "content": "#!/usr/bin/env python3\n\\"\\"\\\"\njob_runner.py \u2014 Production cron job runner.\n\nExecutes a fixed set of build/test/lint jobs, commits results to a local Git\nrepository, and persists run state to a JSON file.  All log output goes through\nPython's standard \`\`logging\`\` module (RotatingFileHandler + StreamHandler).\n\\"\\"\\\"\n\nimport json\nimport logging\nimport logging.handlers\nimport os\nimport subprocess\nimport tempfile\nfrom datetime import datetime\nfrom pathlib import Path\nfrom typing import Optional\n\n# ---------------------------------------------------------------------------\n# Paths \u2014 resolved from environment variables so deployments can override them\n# without changing the file.\n# ---------------------------------------------------------------------------\nWORKSPACE: Path = Path(os.environ.get(\\"JOB_RUNNER_WORKSPACE\\", \\"/home/runner/workspace\\"))\nSTATE_FILE: Path = WORKSPACE / \\"job_state.json\\"\nLOG_DIR: Path = Path(os.environ.get(\\"JOB_RUNNER_LOG_DIR\\", str(WORKSPACE / \\"logs\\")))\nGIT_REPO: Path = Path(os.environ.get(\\"JOB_RUNNER_GIT_REPO\\", str(WORKSPACE / \\"output-repo\\")))\n\n# Module-level logger; configured in setup_logging().\nlogger = logging.getLogger(__name__)\n\n\n# ---------------------------------------------------------------------------\n# Logging\n# ---------------------------------------------------------------------------\n\ndef setup_logging() -> None:\n    \\"\\"\\\"Configure the root logger with a RotatingFileHandler and StreamHandler.\n\n    Reads the desired log level from the \`\`LOG_LEVEL\`\` environment variable\n    (default: \`\`INFO\`\`).  The log directory is created if it does not exist.\n    Handler
