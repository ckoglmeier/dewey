#!/usr/bin/env bash
# Classroom skill scheduler
#
# Creates or removes a scheduled (cron/launchd) job for a Classroom skill.
# Called by the Guide skill on behalf of the user after they confirm a schedule.
#
# Usage:
#   classroom-schedule.sh --skill <name> --trigger daily --time HH:MM [--dry-run]
#   classroom-schedule.sh --skill <name> --trigger weekly --day <0-7> --time HH:MM [--dry-run]
#   classroom-schedule.sh --skill <name> --remove [--dry-run]
#
# Options:
#   --skill    Skill name (kebab-case, e.g. weekly-status-update)
#   --trigger  daily | weekly
#   --time     HH:MM in 24-hour format (e.g. 08:00)
#   --day      Day of week for weekly: 0=Sun,1=Mon,...,6=Sat,7=Sun (cron convention)
#   --context  Optional extra context appended to the claude --print prompt
#   --remove   Remove an existing scheduled job for this skill
#   --dry-run  Print what would be done, don't actually do it

set -euo pipefail

# ---- Defaults ---------------------------------------------------------------
SKILL=""
TRIGGER=""
TIME_HMS=""
DAY_OF_WEEK=""
CONTEXT=""
REMOVE=0
DRY_RUN=0

CLAUDE_BIN="$(command -v claude 2>/dev/null || echo "/usr/local/bin/claude")"
LOG_DIR="$HOME/classroom-logs"
SCHEDULED_DIR="$HOME/.claude/classroom-scheduled"
LABEL_PREFIX="com.classroom"
CLASSROOM_PLATFORM="${CLASSROOM_PLATFORM:-}"

# ---- Helpers ----------------------------------------------------------------
die()  { printf "\033[1;31m✗\033[0m %s\n" "$*" >&2; exit 1; }
say()  { printf "\033[1;36m▸\033[0m %s\n" "$*"; }
note() { printf "  %s\n" "$*"; }
xml_escape() {
  local s="$1"
  s="${s//&/&amp;}"
  s="${s//</&lt;}"
  s="${s//>/&gt;}"
  s="${s//\"/&quot;}"
  s="${s//\'/&apos;}"
  printf "%s" "$s"
}
shell_quote() {
  printf "%q" "$1"
}

# ---- Argument parsing -------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skill)    SKILL="$2";        shift 2 ;;
    --trigger)  TRIGGER="$2";      shift 2 ;;
    --time)     TIME_HMS="$2";     shift 2 ;;
    --day)      DAY_OF_WEEK="$2";  shift 2 ;;
    --context)  CONTEXT="$2";      shift 2 ;;
    --remove)   REMOVE=1;          shift   ;;
    --dry-run)  DRY_RUN=1;         shift   ;;
    *) die "Unknown argument: $1" ;;
  esac
done

[ -n "$SKILL" ] || die "--skill is required"

# Normalise: kebab-case only
if ! echo "$SKILL" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
  die "--skill must be kebab-case (got: $SKILL)"
fi

LABEL="${LABEL_PREFIX}.${SKILL}"

# ---- Platform detection -----------------------------------------------------
if [[ -z "$CLASSROOM_PLATFORM" ]]; then
  if [[ "$(uname)" == "Darwin" ]]; then
    CLASSROOM_PLATFORM=macos
  else
    CLASSROOM_PLATFORM=linux
  fi
fi

if [[ "$CLASSROOM_PLATFORM" == "macos" ]]; then
  PLATFORM=macos
  PLIST_DIR="$HOME/Library/LaunchAgents"
  PLIST_FILE="$PLIST_DIR/${LABEL}.plist"
elif [[ "$CLASSROOM_PLATFORM" == "linux" ]]; then
  PLATFORM=linux
else
  die "CLASSROOM_PLATFORM must be macos or linux (got: $CLASSROOM_PLATFORM)"
fi

# ---- Remove path ------------------------------------------------------------
if [[ "$REMOVE" -eq 1 ]]; then
  if [[ "$PLATFORM" == "macos" ]]; then
    if [[ -f "$PLIST_FILE" ]]; then
      if [[ "$DRY_RUN" -eq 1 ]]; then
        say "[dry-run] Would unload and remove: $PLIST_FILE"
      else
        launchctl unload "$PLIST_FILE" 2>/dev/null || true
        rm -f "$PLIST_FILE"
        say "Removed scheduled job for $SKILL"
      fi
    else
      say "No scheduled job found for $SKILL (expected $PLIST_FILE)"
    fi
  else
    # Linux: remove the crontab line
    CRON_MARKER="# classroom:${SKILL}"
    WRAPPER_SCRIPT="$SCHEDULED_DIR/${SKILL}.sh"
    existing="$(crontab -l 2>/dev/null || true)"
    if echo "$existing" | grep -qF "$CRON_MARKER"; then
      if [[ "$DRY_RUN" -eq 1 ]]; then
        say "[dry-run] Would remove crontab line containing: $CRON_MARKER"
        say "[dry-run] Would remove wrapper: $WRAPPER_SCRIPT"
      else
        echo "$existing" | grep -vF "$CRON_MARKER" | crontab -
        rm -f "$WRAPPER_SCRIPT"
        say "Removed scheduled job for $SKILL from crontab"
      fi
    else
      say "No crontab entry found for $SKILL"
    fi
  fi
  exit 0
fi

# ---- Validation (create path) -----------------------------------------------
[ -n "$TRIGGER" ] || die "--trigger is required (daily or weekly)"
[[ "$TRIGGER" == "daily" || "$TRIGGER" == "weekly" ]] || die "--trigger must be daily or weekly"
[ -n "$TIME_HMS" ] || die "--time is required (HH:MM)"

if ! echo "$TIME_HMS" | grep -qE '^([01][0-9]|2[0-3]):[0-5][0-9]$'; then
  die "--time must be HH:MM in 24-hour format (e.g. 08:00)"
fi

HOUR="${TIME_HMS%%:*}"
MINUTE="${TIME_HMS##*:}"
# Strip leading zeros for cron (bash arithmetic would give octal issues)
HOUR_N="$(echo "$HOUR" | sed 's/^0*//' | grep . || echo 0)"
MINUTE_N="$(echo "$MINUTE" | sed 's/^0*//' | grep . || echo 0)"

if [[ "$TRIGGER" == "weekly" ]]; then
  [ -n "$DAY_OF_WEEK" ] || die "--day is required for weekly trigger (0=Sun,1=Mon,...,6=Sat)"
  if ! echo "$DAY_OF_WEEK" | grep -qE '^[0-7]$'; then
    die "--day must be 0–7 (0=Sun,1=Mon,...,6=Sat,7=Sun)"
  fi
fi

# ANTHROPIC_API_KEY check
API_KEY="${ANTHROPIC_API_KEY:-}"
if [[ -z "$API_KEY" ]]; then
  die "ANTHROPIC_API_KEY is not set in the current environment. Set it in your shell profile and re-run."
fi

# ---- Build the claude command -----------------------------------------------
PROMPT_TEXT="Run /${SKILL}"
if [[ -n "$CONTEXT" ]]; then
  PROMPT_TEXT="${PROMPT_TEXT} — ${CONTEXT}"
fi
PROMPT_TEXT="${PROMPT_TEXT} (scheduled run, $(date +%Y-%m-%d))"

LOG_FILE="${LOG_DIR}/${SKILL}.log"
ERR_LOG_FILE="${LOG_DIR}/${SKILL}.err.log"

# ---- macOS: write launchd plist ---------------------------------------------
if [[ "$PLATFORM" == "macos" ]]; then

  if [[ "$TRIGGER" == "daily" ]]; then
    CALENDAR_INTERVAL="
    <key>StartCalendarInterval</key>
    <dict>
      <key>Hour</key>
      <integer>${HOUR_N}</integer>
      <key>Minute</key>
      <integer>${MINUTE_N}</integer>
    </dict>"
  else
    CALENDAR_INTERVAL="
    <key>StartCalendarInterval</key>
    <dict>
      <key>Weekday</key>
      <integer>${DAY_OF_WEEK}</integer>
      <key>Hour</key>
      <integer>${HOUR_N}</integer>
      <key>Minute</key>
      <integer>${MINUTE_N}</integer>
    </dict>"
  fi

  LABEL_XML="$(xml_escape "$LABEL")"
  CLAUDE_BIN_XML="$(xml_escape "$CLAUDE_BIN")"
  PROMPT_TEXT_XML="$(xml_escape "$PROMPT_TEXT")"
  API_KEY_XML="$(xml_escape "$API_KEY")"
  LOG_FILE_XML="$(xml_escape "$LOG_FILE")"
  ERR_LOG_FILE_XML="$(xml_escape "$ERR_LOG_FILE")"

  PLIST_CONTENT="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
  <key>Label</key>
  <string>${LABEL_XML}</string>
  <key>ProgramArguments</key>
  <array>
    <string>${CLAUDE_BIN_XML}</string>
    <string>--print</string>
    <string>${PROMPT_TEXT_XML}</string>
  </array>
  ${CALENDAR_INTERVAL}
  <key>EnvironmentVariables</key>
  <dict>
    <key>ANTHROPIC_API_KEY</key>
    <string>${API_KEY_XML}</string>
  </dict>
  <key>StandardOutPath</key>
  <string>${LOG_FILE_XML}</string>
  <key>StandardErrorPath</key>
  <string>${ERR_LOG_FILE_XML}</string>
</dict>
</plist>"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    say "[dry-run] Would write plist to: $PLIST_FILE"
    echo "---"
    echo "$PLIST_CONTENT"
    echo "---"
    say "[dry-run] Would run: launchctl load $PLIST_FILE"
    say "[dry-run] Log output would go to: $LOG_FILE"
    exit 0
  fi

  mkdir -p "$PLIST_DIR"
  mkdir -p "$LOG_DIR"

  # Unload existing job if present (idempotent)
  if [[ -f "$PLIST_FILE" ]]; then
    launchctl unload "$PLIST_FILE" 2>/dev/null || true
  fi

  echo "$PLIST_CONTENT" > "$PLIST_FILE"
  launchctl load "$PLIST_FILE"

  say "Scheduled: $SKILL"
  note "Trigger:   $TRIGGER at $TIME_HMS${DAY_OF_WEEK:+ on weekday $DAY_OF_WEEK}"
  note "Log:       $LOG_FILE"
  note "Plist:     $PLIST_FILE"
  note ""
  note "To unschedule: /classroom schedule → unschedule"
  note "Or manually:   launchctl unload $PLIST_FILE && rm $PLIST_FILE"

# ---- Linux: write crontab entry ---------------------------------------------
else
  if [[ "$TRIGGER" == "daily" ]]; then
    CRON_SCHEDULE="${MINUTE_N} ${HOUR_N} * * *"
  else
    CRON_SCHEDULE="${MINUTE_N} ${HOUR_N} * * ${DAY_OF_WEEK}"
  fi

  WRAPPER_SCRIPT="${SCHEDULED_DIR}/${SKILL}.sh"
  API_KEY_Q="$(shell_quote "$API_KEY")"
  LOG_DIR_Q="$(shell_quote "$LOG_DIR")"
  CLAUDE_BIN_Q="$(shell_quote "$CLAUDE_BIN")"
  PROMPT_TEXT_Q="$(shell_quote "$PROMPT_TEXT")"
  LOG_FILE_Q="$(shell_quote "$LOG_FILE")"

  WRAPPER_CONTENT="#!/usr/bin/env bash
set -euo pipefail
export ANTHROPIC_API_KEY=${API_KEY_Q}
mkdir -p ${LOG_DIR_Q}
exec ${CLAUDE_BIN_Q} --print ${PROMPT_TEXT_Q} >> ${LOG_FILE_Q} 2>&1"

  WRAPPER_SCRIPT_Q="$(shell_quote "$WRAPPER_SCRIPT")"
  CRON_LINE="${CRON_SCHEDULE} ${WRAPPER_SCRIPT_Q} # classroom:${SKILL}"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    say "[dry-run] Would write wrapper to: $WRAPPER_SCRIPT"
    echo "---"
    echo "$WRAPPER_CONTENT"
    echo "---"
    say "[dry-run] Would add crontab line:"
    echo "  $CRON_LINE"
    say "[dry-run] Log output would go to: $LOG_FILE"
    exit 0
  fi

  mkdir -p "$LOG_DIR"
  mkdir -p "$SCHEDULED_DIR"
  printf "%s\n" "$WRAPPER_CONTENT" > "$WRAPPER_SCRIPT"
  chmod 700 "$WRAPPER_SCRIPT"

  existing="$(crontab -l 2>/dev/null || true)"
  # Remove any existing entry for this skill first (idempotent)
  cleaned="$(echo "$existing" | grep -v "# classroom:${SKILL}" || true)"
  { echo "$cleaned"; echo "$CRON_LINE"; } | crontab -

  say "Scheduled: $SKILL"
  note "Trigger:   $TRIGGER at $TIME_HMS${DAY_OF_WEEK:+ on weekday $DAY_OF_WEEK}"
  note "Cron:      $CRON_SCHEDULE"
  note "Log:       $LOG_FILE"
  note ""
  note "To unschedule: /classroom schedule → unschedule"
  note "Or manually:   crontab -e  (remove the # classroom:${SKILL} line)"
fi
