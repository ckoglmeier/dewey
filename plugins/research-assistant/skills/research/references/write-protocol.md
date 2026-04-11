# Write Protocol — Shared Agent Instructions

Inject this verbatim into every research agent's skeleton file and agent prompt.

---

```
CRITICAL WRITE PROTOCOL — READ THIS BEFORE DOING ANYTHING:

YOU WILL BE STOPPED AND RELAUNCHED IF YOU VIOLATE THIS PROTOCOL.

════════════════════════════════════════════════════════
STEP 0 — DATA FILES DO NOT SUBSTITUTE FOR WEB RESEARCH
════════════════════════════════════════════════════════

If data files have been provided (Excel, CSV, PDF, uploaded documents):
1. READ AND EXTRACT them FIRST. Write the extracted data directly into your
   output file under a "Pre-loaded Data" section at the top.
2. Then proceed with web research EXACTLY AS NORMAL.
3. During write-up, integrate the file data into the relevant sections.
   Do NOT write a separate "file data" document — weave it in.
4. Tag file-sourced data as [INTERNAL DATA] or the appropriate confidence tag.

Data files tell you about the COMPANY'S existing position.
Web research tells you about the EXTERNAL LANDSCAPE.
You need both. Files never replace the web research loop.

If WebSearch or WebFetch is unavailable, state this explicitly at the top of
your output and downgrade all web-sourced claims to [ESTIMATE] or lower.

════════════════════════════════════════════════════════

The ONLY acceptable pattern is: Search -> Edit -> Search -> Edit -> Search -> Edit.
NEVER: Search -> Search. NO EXCEPTIONS. NOT EVEN ONCE.

You MUST Edit your output file after EVERY SINGLE search or web fetch.
If you do two searches in a row without an Edit to your file, you are VIOLATING THE
PROTOCOL and will be killed.

Work through your sections IN ORDER (1, 2, 3...). For each section:
1. Do ONE search or web fetch
2. IMMEDIATELY Edit the file to write what you learned under that section
3. Do another search if needed
4. IMMEDIATELY Edit the file again with additional findings
5. Only move to the next section after the current one has real content

If a web fetch returns a 403 error, do NOT try multiple alternative URLs before writing.
Write what you have so far, THEN try another URL, THEN write again.

Every quantitative claim needs an inline source URL: [Source Name](https://url.com)
Do NOT put sources at the bottom. Inline only.

SOURCE URL RULE: Every URL you cite MUST be one you actually visited via WebFetch
or found via WebSearch in THIS session. Do NOT construct URLs from memory or guess
at URL patterns. If you cannot find a source URL for a claim, either (a) find the
source, (b) attribute it as "[Source Name, accessed via web search]" without a URL,
or (c) tag it [UNVERIFIED]. Never fabricate a URL.

When ALL sections are complete, change the file's Status line from "IN PROGRESS" to "COMPLETE".
```
