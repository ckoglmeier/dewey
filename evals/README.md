# Dewey WS3 Eval Harness

Evaluates routing and flow quality for the Dewey Guide skill. Extends the
Phase 3 design from `docs/plans/skill-trigger-validation.md` and corresponds
to WS3 in `docs/plans/go-to-market.md`.

**This harness costs API credits and is NOT part of the hermetic test suite.**
It is opt-in and network-gated, like Layer 8.

---

## What it evaluates

### 1. Trigger routing (`evals/cases/trigger_routing.jsonl`)

For each in-tree SKILL.md (excluding `user-invocable: false` skills), we take
every trigger string and ask a model: "given this user utterance and the list
of all skill descriptors, which skill would you invoke?" The model's answer is
compared to `expect_skill`.

Launch bar: **>= 90% accuracy**.

Cases are generated from the live repo by `evals/gen_cases.py` and committed
so the eval works even without regenerating. Regenerate after any skill or
trigger change:

```bash
python3 evals/gen_cases.py
```

### 2. Guide flows (`evals/cases/guide_flows.jsonl`)

Hand-authored scenarios covering the Guide's main subcommands (`recommend`,
`install`, `extend`, `license`, `admin-setup`) plus edge cases. Each case has
a persona, a prompt, and a list of plain-English outcome assertions (e.g.
"shows a confirm block before acting", "does not install without user approval").

The model reads the full `guide/SKILL.md` text and judges whether each
assertion would hold.

Launch bar: **100% of assertions pass**.

---

## Running the eval

### Prerequisites

1. Set `DEWEY_EVAL=1` — without this the runner exits 77 (skip) immediately.
2. Configure a backend (see below).

### Backend modes

**Option 1: Anthropic SDK**

```bash
pip install anthropic
export DEWEY_EVAL=1
export ANTHROPIC_API_KEY=sk-ant-...
# Optional: override the model (default: claude-sonnet-4-6)
export DEWEY_EVAL_MODEL=claude-haiku-4-5
python3 evals/run_eval.py
```

This uses the Anthropic Messages API directly. The SDK is imported lazily
inside the API path — it is never loaded during the hermetic test suite.

**Option 2: subprocess command (advanced models or proxies)**

```bash
export DEWEY_EVAL=1
export DEWEY_EVAL_BACKEND=cmd
export DEWEY_EVAL_CMD="my-model-cli --model claude-opus-4-5"
python3 evals/run_eval.py
```

The command receives the prompt on stdin and must print the model's response
to stdout. Exit nonzero on error. This lets the orchestrator pipe in any model
without requiring the `anthropic` package.

**No backend configured**

```bash
DEWEY_EVAL= python3 evals/run_eval.py
# → exits 77 with a clear message
```

---

## Output

- **stdout** — human-readable summary: accuracy, pass rate, list of misroutes
  and failed assertions.
- **`evals/last_report.json`** — structured JSON with skill-level accuracy,
  per-flow pass rate, and full detail for every case.

Exit codes:
- `0` — all launch bars met
- `1` — a backend ran but results are below bar (can gate CI)
- `2` — error (bad config, file not found)
- `77` — skipped (no gate or no backend)

---

## CI wiring

The eval is **not** in the default `bash tests/run.sh` suite (that suite stays
fully hermetic). Wire it separately:

```yaml
# .github/workflows/eval.yml (example)
- name: Run eval
  if: env.ANTHROPIC_API_KEY != ''
  env:
    DEWEY_EVAL: "1"
    ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
    DEWEY_EVAL_MODEL: claude-haiku-4-5   # cheap model for CI
  run: python3 evals/run_eval.py
```

Run on PRs touching `guide/`, `plugins/admin/`, or any `SKILL.md`; nightly
otherwise. The eval exits nonzero when below bar, so it can block merge when
configured as a required check.

---

## Regenerating trigger cases

`evals/gen_cases.py` scans `plugins/*/skills/*/SKILL.md`, skips
`user-invocable: false` skills, and emits one line per trigger string. It uses
only stdlib and is deterministic (output is sorted by path).

```bash
python3 evals/gen_cases.py           # writes evals/cases/trigger_routing.jsonl
python3 evals/gen_cases.py --stdout  # prints to stdout
```

`tests/layers/layer-17-eval.sh` asserts that regenerating produces identical
output (catches drift between skills and committed cases).

---

## Cost estimate

With `claude-haiku-4-5` as the eval model (~$0.10 per run for 130 trigger cases
+ 8 flow cases with ~8 assertions each):

- Trigger routing: ~130 calls × ~300 tokens each ≈ $0.05–0.08
- Guide flows: ~8 calls × ~3,000 tokens each (guide text + prompt) ≈ $0.02–0.05
- Total per run: **roughly $0.10**, comfortably cached by content hash in most
  CI systems.
