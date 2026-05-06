# Scheduled and headless skill runs

Classroom skills run conversationally by default — you type `/meeting-prep` and Claude responds. But some skills are useful on a recurring schedule without you being in the loop: a weekly status draft ready in your editor Monday morning, a competitive intelligence digest every Friday, a daily standup summary.

Use `/classroom schedule` to set one up. The Guide walks you through it and calls `~/.claude/classroom-schedule.sh` to create the job.

## Prerequisites

**ANTHROPIC_API_KEY must be available in your cron/launchd environment.** This is the main gotcha. When macOS launchd or Linux cron runs a job, it uses a minimal environment — your shell profile isn't sourced. The scheduler writes the key into the job definition so it's always present.

```bash
# Confirm you have it set
echo $ANTHROPIC_API_KEY
```

If it's empty, get it from [console.anthropic.com](https://console.anthropic.com) and set it in your shell profile first.

## How it works

Under the hood, each scheduled job runs:

```bash
claude --print "Run /skill-name for <context>" >> ~/classroom-logs/<skill-name>.log 2>&1
```

`--print` runs Claude non-interactively: it receives the prompt, executes the skill, writes the output to the log file, and exits. No terminal required.

Output accumulates in `~/classroom-logs/`. Check it any time:

```bash
cat ~/classroom-logs/weekly-status-update.log
```

## macOS (launchd)

The scheduler writes a `.plist` to `~/Library/LaunchAgents/com.classroom.<skill>.plist` and loads it immediately. Jobs survive reboots automatically.

Example plist for a weekly status update every Monday at 8 AM:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.classroom.weekly-status-update</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>-c</string>
    <string>claude --print "Run /weekly-status-update for week of $(date +%Y-%m-%d)" >> ~/classroom-logs/weekly-status-update.log 2>&1</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Weekday</key>
    <integer>1</integer>
    <key>Hour</key>
    <integer>8</integer>
    <key>Minute</key>
    <integer>0</integer>
  </dict>
  <key>EnvironmentVariables</key>
  <dict>
    <key>ANTHROPIC_API_KEY</key>
    <string>sk-ant-...</string>
  </dict>
  <key>StandardOutPath</key>
  <string>/tmp/classroom-weekly-status-update.out</string>
  <key>StandardErrorPath</key>
  <string>/tmp/classroom-weekly-status-update.err</string>
</dict>
</plist>
```

**Managing launchd jobs:**

```bash
# List Classroom jobs
launchctl list | grep com.classroom

# Unload (stop + disable)
launchctl unload ~/Library/LaunchAgents/com.classroom.<skill>.plist

# Reload after editing
launchctl unload ~/Library/LaunchAgents/com.classroom.<skill>.plist
launchctl load ~/Library/LaunchAgents/com.classroom.<skill>.plist
```

## Linux (cron)

The scheduler adds a line to your crontab. Example for the same Monday 8 AM job:

```
0 8 * * 1 ANTHROPIC_API_KEY=sk-ant-... /usr/local/bin/claude --print "Run /weekly-status-update for week of $(date +\%Y-\%m-\%d)" >> ~/classroom-logs/weekly-status-update.log 2>&1
```

**Managing cron jobs:**

```bash
# View your crontab
crontab -l

# Edit manually
crontab -e

# Remove all Classroom jobs (careful)
crontab -l | grep -v 'com.classroom\|classroom-logs' | crontab -
```

## Unscheduling

Use `/classroom schedule` and choose "unschedule" — the Guide will call the scheduler with `--remove` to delete the job and plist/crontab entry.

Or manually:

```bash
# macOS
launchctl unload ~/Library/LaunchAgents/com.classroom.<skill>.plist
rm ~/Library/LaunchAgents/com.classroom.<skill>.plist

# Linux — edit crontab and remove the line
crontab -e
```

## Logs and troubleshooting

```bash
# See all scheduled skill output
ls ~/classroom-logs/

# Watch a log live
tail -f ~/classroom-logs/weekly-status-update.log

# macOS: check launchd stderr for job startup errors
cat /tmp/classroom-<skill>.err
```

Common issues:
- **"command not found: claude"** — Claude Code isn't on the PATH that cron/launchd uses. The scheduler uses the full path from `which claude` when creating the job. If you moved Claude Code, remove and re-create the scheduled job.
- **Empty log file** — The ANTHROPIC_API_KEY is wrong or expired. Check `echo $ANTHROPIC_API_KEY` and re-run `/classroom schedule`.
- **Job not running** — On macOS, `launchctl list | grep com.classroom` should show the job. If it's missing, re-run `/classroom schedule`.
