# ============================================================================
# LAYER 2: SKILL FRONTMATTER
# ============================================================================
section "Layer 2 — Skill frontmatter checks"

# All SKILL.md files (plugins + guide). bash 3.2 compatible (no mapfile).
SKILL_FILES=()
while IFS= read -r line; do
  SKILL_FILES+=("$line")
done < <(find guide plugins -name 'SKILL.md' | sort)

check "found at least 1 skill file" \
  "test ${#SKILL_FILES[@]} -gt 0"

for skill in "${SKILL_FILES[@]}"; do
  rel="${skill#./}"

  check "[$rel] starts with --- frontmatter delimiter" \
    "head -1 '$skill' | grep -q '^---$'"

  # Parse the YAML frontmatter via python (no PyYAML — use a tiny manual parser)
  check "[$rel] has parseable frontmatter with description" \
    "python3 -c '
import sys, re
text = open(\"$skill\").read()
m = re.match(r\"^---\n(.*?)\n---\n\", text, re.DOTALL)
assert m, \"no frontmatter block found\"
fm = m.group(1)
fields = {}
for line in fm.splitlines():
    if \":\" in line and not line.startswith(\" \"):
        k, _, v = line.partition(\":\")
        fields[k.strip()] = v.strip().strip(\"\\\"\").strip(\"'\\''\")
assert \"description\" in fields, \"missing required: description\"
desc = fields[\"description\"]
assert len(desc) > 0, \"description is empty\"
'"

  check "[$rel] description under 250 chars (truncation safe)" \
    "python3 -c '
import re
text = open(\"$skill\").read()
m = re.match(r\"^---\n(.*?)\n---\n\", text, re.DOTALL)
fm = m.group(1)
for line in fm.splitlines():
    if line.startswith(\"description:\"):
        desc = line.split(\":\", 1)[1].strip().strip(chr(34)).strip(chr(39))
        assert len(desc) <= 250, \"description \" + str(len(desc)) + \" > 250\"
        break
'"

  check "[$rel] name field (if present) is kebab-case ≤64 chars" \
    "python3 -c '
import re
text = open(\"$skill\").read()
m = re.match(r\"^---\n(.*?)\n---\n\", text, re.DOTALL)
fm = m.group(1)
for line in fm.splitlines():
    if line.startswith(\"name:\"):
        name = line.split(\":\", 1)[1].strip().strip(chr(34)).strip(chr(39))
        assert re.fullmatch(r\"[a-z0-9]+(-[a-z0-9]+)*\", name), \"not kebab-case: \" + name
        assert len(name) <= 64, \"too long: \" + str(len(name))
        break
'"

  check "[$rel] body has non-trivial content (>200 chars after frontmatter)" \
    "python3 -c '
import re
text = open(\"$skill\").read()
body = re.sub(r\"^---\n.*?\n---\n\", \"\", text, count=1, flags=re.DOTALL)
stripped = body.strip()
assert len(stripped) > 200, \"body only \" + str(len(stripped)) + \" chars\"
'"
done
