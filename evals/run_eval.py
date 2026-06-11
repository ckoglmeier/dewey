#!/usr/bin/env python3
"""Dewey WS3 eval runner.

Evaluates two categories:
  1. Trigger routing   — given a user utterance and all skill descriptors, does
                         a model pick the right skill name? (trigger_routing.jsonl)
  2. Guide flows       — given the Guide SKILL.md and a flow prompt, does the
                         model confirm each plain-English outcome assertion?
                         (guide_flows.jsonl)

Backend selection (first match wins):
  1. DEWEY_EVAL_BACKEND=api AND ANTHROPIC_API_KEY set AND `anthropic` importable
     → Anthropic SDK, model from DEWEY_EVAL_MODEL (default: claude-sonnet-4-6)
  2. DEWEY_EVAL_BACKEND=cmd (or fallback) AND DEWEY_EVAL_CMD set
     → subprocess, reads prompt on stdin, model text on stdout
  3. None of the above → exit 77 with a clear message (same skip-code as Layer 8)

Gate:
  DEWEY_EVAL=1 must be set, or the runner exits 77 immediately.

Launch bars:
  Trigger routing: >= 90% accuracy
  Guide flows:     100% of assertions pass

Output:
  evals/last_report.json — structured results
  stdout               — human summary
  exit code            — nonzero when a backend ran AND results are below bar
                         77 when skipped; 0 on pass; 1 on below bar; 2 on error

Usage:
  DEWEY_EVAL=1 ANTHROPIC_API_KEY=sk-... python3 evals/run_eval.py
  DEWEY_EVAL=1 DEWEY_EVAL_BACKEND=cmd DEWEY_EVAL_CMD="cat /tmp/fake-model.sh" python3 evals/run_eval.py
  DEWEY_EVAL= python3 evals/run_eval.py   # exits 77
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
import textwrap
from pathlib import Path

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
REPO_ROOT = Path(__file__).parent.parent
EVALS_DIR = REPO_ROOT / "evals"
CASES_DIR = EVALS_DIR / "cases"
TRIGGER_CASES = CASES_DIR / "trigger_routing.jsonl"
FLOW_CASES = CASES_DIR / "guide_flows.jsonl"
GUIDE_SKILL = REPO_ROOT / "guide" / "SKILL.md"
REPORT_PATH = EVALS_DIR / "last_report.json"

# Launch bars
TRIGGER_BAR = 0.90
FLOW_BAR = 1.00

DEFAULT_MODEL = "claude-sonnet-4-6"


# ---------------------------------------------------------------------------
# Gate check
# ---------------------------------------------------------------------------
def check_gate() -> None:
    """Exit 77 (skip) if DEWEY_EVAL is not '1'."""
    if os.environ.get("DEWEY_EVAL", "0") != "1":
        print(
            "evals/run_eval.py: skipped — set DEWEY_EVAL=1 to enable\n"
            "  (also needs a backend: ANTHROPIC_API_KEY or DEWEY_EVAL_BACKEND=cmd + DEWEY_EVAL_CMD)"
        )
        sys.exit(77)


# ---------------------------------------------------------------------------
# Backend resolution
# ---------------------------------------------------------------------------

def _try_anthropic_backend() -> "callable | None":
    """Return a call(prompt) → str function using the Anthropic SDK, or None."""
    api_key = os.environ.get("ANTHROPIC_API_KEY", "")
    if not api_key:
        return None
    backend_env = os.environ.get("DEWEY_EVAL_BACKEND", "")
    if backend_env and backend_env != "api":
        return None  # Explicit non-api backend requested
    try:
        import anthropic  # noqa: PLC0415  (lazy import intentional)
    except ImportError:
        return None

    model = os.environ.get("DEWEY_EVAL_MODEL", DEFAULT_MODEL)

    client = anthropic.Anthropic(api_key=api_key)

    def call(prompt: str) -> str:
        message = client.messages.create(
            model=model,
            max_tokens=512,
            messages=[{"role": "user", "content": prompt}],
        )
        return message.content[0].text

    print(f"[eval] backend: anthropic SDK, model={model}")
    return call


def _try_cmd_backend() -> "callable | None":
    """Return a call(prompt) → str function via subprocess, or None."""
    backend_env = os.environ.get("DEWEY_EVAL_BACKEND", "")
    cmd = os.environ.get("DEWEY_EVAL_CMD", "")
    if backend_env not in ("cmd", "") or not cmd:
        return None
    if not cmd:
        return None

    print(f"[eval] backend: cmd={cmd!r}")

    def call(prompt: str) -> str:
        result = subprocess.run(
            cmd,
            shell=True,
            input=prompt,
            capture_output=True,
            text=True,
            timeout=120,
        )
        if result.returncode != 0:
            raise RuntimeError(
                f"DEWEY_EVAL_CMD exited {result.returncode}: {result.stderr[:200]}"
            )
        return result.stdout

    return call


def resolve_backend() -> "callable":
    """Return a call(prompt) → str function, or exit 77."""
    backend = _try_anthropic_backend() or _try_cmd_backend()
    if backend is None:
        print(
            "evals/run_eval.py: no eval backend configured — skipping.\n"
            "  To run evals:\n"
            "    Option 1 (SDK):  set ANTHROPIC_API_KEY and install the `anthropic` package\n"
            "    Option 2 (cmd):  set DEWEY_EVAL_BACKEND=cmd and DEWEY_EVAL_CMD=<command>\n"
            "                     The command reads the prompt on stdin and returns model text on stdout."
        )
        sys.exit(77)
    return backend


# ---------------------------------------------------------------------------
# Case loading
# ---------------------------------------------------------------------------

def load_jsonl(path: Path) -> list[dict]:
    cases = []
    with open(path, encoding="utf-8") as f:
        for i, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue
            try:
                cases.append(json.loads(line))
            except json.JSONDecodeError as e:
                print(f"[warn] {path.name}:{i}: JSON parse error: {e}", file=sys.stderr)
    return cases


def load_guide_skill() -> str:
    if not GUIDE_SKILL.exists():
        raise FileNotFoundError(f"guide/SKILL.md not found at {GUIDE_SKILL}")
    return GUIDE_SKILL.read_text(encoding="utf-8")


# ---------------------------------------------------------------------------
# Trigger routing eval
# ---------------------------------------------------------------------------

def build_routing_catalog(cases: list[dict]) -> list[dict]:
    """Deduplicate to unique (skill, plugin) descriptors. We don't have
    descriptions in the case file, so we re-read from SKILL.md files."""
    seen: dict[str, dict] = {}
    for case in cases:
        skill = case["skill"]
        if skill in seen:
            continue
        skill_md = REPO_ROOT / "plugins" / case["plugin"] / "skills" / skill / "SKILL.md"
        description = ""
        if skill_md.exists():
            text = skill_md.read_text(encoding="utf-8")
            import re
            m = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
            if m:
                fm = m.group(1)
                dm = re.search(r"^description\s*:\s*(.+)", fm, re.MULTILINE)
                if dm:
                    description = dm.group(1).strip().strip("\"'")
        seen[skill] = {"name": skill, "plugin": case["plugin"], "description": description}
    return list(seen.values())


def run_trigger_routing(
    cases: list[dict],
    call: "callable",
) -> dict:
    """Returns a results dict with per-case outcomes and aggregate accuracy."""
    catalog = build_routing_catalog(cases)
    catalog_text = "\n".join(
        f"  - {s['name']} ({s['plugin']}): {s['description']}" for s in catalog
    )

    results = []
    correct = 0

    for case in cases:
        utterance = case["trigger"]
        expect = case["expect_skill"]

        prompt = textwrap.dedent(f"""
            You are a skill router. Given a user utterance and a list of available skills,
            respond with exactly ONE skill name from the list — the skill you would invoke.
            Output ONLY the skill name, nothing else (no explanation, no punctuation).

            Available skills:
            {catalog_text}

            User utterance: "{utterance}"

            Skill name:""").strip()

        try:
            response = call(prompt).strip()
            # Normalize: strip punctuation, lowercase for comparison
            got = response.strip().strip(".,;:\"'").lower()
            exp = expect.lower()
            ok = got == exp
        except Exception as e:
            response = f"ERROR: {e}"
            ok = False

        results.append({
            "trigger": utterance,
            "skill": case["skill"],
            "plugin": case["plugin"],
            "expect_skill": expect,
            "got": response,
            "pass": ok,
        })
        if ok:
            correct += 1

    accuracy = correct / len(cases) if cases else 0.0
    misroutes = [r for r in results if not r["pass"]]

    return {
        "total": len(cases),
        "correct": correct,
        "accuracy": accuracy,
        "pass": accuracy >= TRIGGER_BAR,
        "bar": TRIGGER_BAR,
        "misroutes": misroutes,
        "results": results,
    }


# ---------------------------------------------------------------------------
# Guide flow eval
# ---------------------------------------------------------------------------

def run_guide_flows(
    cases: list[dict],
    guide_text: str,
    call: "callable",
) -> dict:
    """Returns a results dict with per-flow, per-assertion outcomes."""
    all_results = []
    all_pass = True

    for case in cases:
        flow = case["flow"]
        persona = case["persona"]
        prompt_text = case["prompt"]
        assertions = case["assert"]

        assertion_list = "\n".join(
            f'  {i + 1}. "{a}"' for i, a in enumerate(assertions)
        )

        prompt = textwrap.dedent(f"""
            You are evaluating whether a conversational AI skill (the Dewey Guide) would
            correctly handle a user interaction.

            Below is the full text of the Dewey Guide skill (guide/SKILL.md):

            ---BEGIN GUIDE SKILL---
            {guide_text}
            ---END GUIDE SKILL---

            Evaluation scenario:
            - Flow: {flow}
            - User persona: {persona}
            - User message: {prompt_text}

            Assertions to evaluate (would the Guide, following its instructions, satisfy each?):
            {assertion_list}

            Respond with a JSON object mapping each assertion number to "pass" or "fail"
            followed by a brief reason. Use this exact format:
            {{
              "1": {{"result": "pass", "reason": "..."}},
              "2": {{"result": "fail", "reason": "..."}}
            }}
            Only output valid JSON. No explanation outside the JSON object.
        """).strip()

        try:
            response = call(prompt).strip()
            # Extract JSON from response (model might wrap in ```json ... ```)
            import re
            json_match = re.search(r'\{.*\}', response, re.DOTALL)
            if json_match:
                parsed = json.loads(json_match.group(0))
            else:
                parsed = json.loads(response)

            assertion_results = []
            flow_pass = True
            for i, assertion in enumerate(assertions):
                key = str(i + 1)
                entry = parsed.get(key, {})
                result = entry.get("result", "fail").lower()
                reason = entry.get("reason", "")
                ok = result == "pass"
                if not ok:
                    flow_pass = False
                    all_pass = False
                assertion_results.append({
                    "assertion": assertion,
                    "result": result,
                    "reason": reason,
                    "pass": ok,
                })

        except Exception as e:
            assertion_results = [
                {"assertion": a, "result": "error", "reason": str(e), "pass": False}
                for a in assertions
            ]
            flow_pass = False
            all_pass = False

        all_results.append({
            "flow": flow,
            "persona": persona,
            "prompt": prompt_text,
            "assertions": assertion_results,
            "pass": flow_pass,
        })

    total_assertions = sum(len(r["assertions"]) for r in all_results)
    passed_assertions = sum(
        sum(1 for a in r["assertions"] if a["pass"]) for r in all_results
    )
    pass_rate = passed_assertions / total_assertions if total_assertions else 0.0

    return {
        "total_flows": len(cases),
        "total_assertions": total_assertions,
        "passed_assertions": passed_assertions,
        "pass_rate": pass_rate,
        "pass": all_pass,
        "bar": FLOW_BAR,
        "results": all_results,
    }


# ---------------------------------------------------------------------------
# Report + summary
# ---------------------------------------------------------------------------

def write_report(routing: dict, flows: dict) -> None:
    report = {
        "trigger_routing": {
            k: v for k, v in routing.items() if k != "results"
        },
        "trigger_routing_detail": routing.get("results", []),
        "guide_flows": {
            k: v for k, v in flows.items() if k != "results"
        },
        "guide_flows_detail": flows.get("results", []),
    }
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(REPORT_PATH, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    print(f"\n[eval] report written → {REPORT_PATH.relative_to(REPO_ROOT)}")


def print_summary(routing: dict, flows: dict) -> None:
    r = routing
    f = flows

    bar_r = f"{r['bar']:.0%}"
    bar_f = f"{f['bar']:.0%}"

    status_r = "PASS" if r["pass"] else "FAIL"
    status_f = "PASS" if f["pass"] else "FAIL"

    print("\n" + "=" * 60)
    print("Dewey WS3 Eval Results")
    print("=" * 60)
    print(
        f"\nTrigger routing:  {r['correct']}/{r['total']} correct "
        f"({r['accuracy']:.1%}) — bar {bar_r} → [{status_r}]"
    )
    print(
        f"Guide flows:      {f['passed_assertions']}/{f['total_assertions']} assertions "
        f"({f['pass_rate']:.1%}) — bar {bar_f} → [{status_f}]"
    )

    if r["misroutes"]:
        print(f"\nMisrouted triggers ({len(r['misroutes'])}):")
        for m in r["misroutes"][:10]:
            print(f"  expected={m['expect_skill']!r:30s} got={m['got']!r:30s}  trigger={m['trigger'][:60]!r}")
        if len(r["misroutes"]) > 10:
            print(f"  ... and {len(r['misroutes']) - 10} more (see last_report.json)")

    failed_flows = [fr for fr in f["results"] if not fr["pass"]]
    if failed_flows:
        print(f"\nFailed flow assertions:")
        for fr in failed_flows:
            print(f"  [{fr['flow']}] {fr['prompt'][:60]!r}")
            for a in fr["assertions"]:
                if not a["pass"]:
                    print(f"    FAIL: {a['assertion']}")
                    if a["reason"]:
                        print(f"          reason: {a['reason'][:100]}")

    print()
    if r["pass"] and f["pass"]:
        print("All launch bars met.")
    else:
        bars_failed = []
        if not r["pass"]:
            bars_failed.append(f"trigger routing < {bar_r}")
        if not f["pass"]:
            bars_failed.append(f"guide flow assertions < {bar_f}")
        print(f"Below launch bar: {', '.join(bars_failed)}")
    print("=" * 60)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> int:
    check_gate()

    call = resolve_backend()

    print("[eval] loading cases...")
    trigger_cases = load_jsonl(TRIGGER_CASES)
    flow_cases = load_jsonl(FLOW_CASES)
    guide_text = load_guide_skill()

    print(f"[eval] {len(trigger_cases)} trigger cases, {len(flow_cases)} flow cases")

    print("[eval] running trigger routing eval...")
    routing_results = run_trigger_routing(trigger_cases, call)

    print("[eval] running guide flow eval...")
    flow_results = run_guide_flows(flow_cases, guide_text, call)

    write_report(routing_results, flow_results)
    print_summary(routing_results, flow_results)

    if routing_results["pass"] and flow_results["pass"]:
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
