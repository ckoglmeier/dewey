---
name: person-profile
description: >
  Build a profile on a person - their background, career trajectory, public positions,
  network, and communication style. Use when someone asks "tell me about [person]",
  "prep me for a meeting with [person]", "who is [person]", "background on [person]",
  "what should I know before meeting [person]", or any request to understand a person
  before a meeting, deal, or relationship. Can be invoked directly or via the research
  orchestrator.
---

# Person Profile Research Type

**Standalone execution:** If invoked directly (not via the research orchestrator),
follow the protocol in `../research/references/standalone-execution.md` to run the
full pipeline: company context -> internal recon -> plan -> launch agents -> monitor ->
synthesize.

Use this type when the goal is to understand a person - their career, positions,
network, communication style, and what matters to them. The primary use case is
meeting preparation, but also applies to investor research, partnership evaluation,
board member assessment, or key-person due diligence.

---

## When to Use This Type

- "Tell me about [person] before my meeting"
- "Who is [person]?"
- "Prep me for a call with [person]"
- "Background on [person] - what should I know?"
- "What has [person] said publicly about [topic]?"
- "Key-person assessment on [person]"

---

## Step 0: Clarify the Context (REQUIRED)

Before launching agents, establish:

1. **Who is this person?** Full name, current role/company (if known).
2. **What's the context?** Meeting prep, investor evaluation, partnership assessment,
   key-person due diligence, or general background?
3. **What do you most need to know?** Their views on a specific topic? Their decision-
   making style? Their career trajectory? Their network?

This shapes which sections get the most depth.

---

## Recommended Agent Workstreams

For most person profiles, plan 2 agents:

**Agent 1: Background and Career**
Sections:
1. Current role and organization - what do they do now? What's their scope and
   influence? How long have they been in this role?
2. Career trajectory - key roles, transitions, and inflection points. Not a full
   resume - focus on the moves that explain who they are now. What pattern emerges?
3. Education and credentials - degrees, certifications, board seats, advisory roles.
   Note anything that signals what they value.
4. Network and affiliations - board memberships, advisory roles, investment
   activity, industry associations, frequent co-panelists or co-authors.
5. Key accomplishments - what are they known for? What have they built, launched,
   or transformed? Be specific.

**Agent 2: Public Voice and Priorities**
Sections:
1. Public positions and thought leadership - what have they written, said in
   interviews, posted on LinkedIn, or spoken about at conferences? What topics
   do they care about? What positions do they take?
2. Communication style signals - based on public appearances, writing, and
   interviews: are they data-driven or narrative-driven? Direct or diplomatic?
   Detail-oriented or big-picture? Formal or casual?
3. Recent activity - what have they been doing in the last 6 months? Recent
   talks, posts, job changes, investments, company announcements?
4. Connection points - based on their interests and positions, what are the
   natural conversation topics or common ground with the user? What would
   they likely want to discuss?

---

## Source Priority (REQUIRED)

Person research requires careful source prioritization. Not all information about
a person is equally reliable or useful.

### Priority order:
1. **Their own words** - LinkedIn posts, articles they've written, conference talks,
   podcast appearances, interviews. This is the most authentic signal of what they
   think and care about.
2. **Professional record** - LinkedIn profile, company bio, board listings, SEC
   filings (for public company officers/directors), patent filings.
3. **Company/organizational context** - press releases, company announcements that
   feature them, organizational charts.
4. **Third-party coverage** - news articles, profiles, mentions in industry press.
   Useful for context but filtered through someone else's framing.
5. **Internal knowledge** - Slack mentions, internal docs, meeting notes that
   reference this person. Check during internal recon.

### What to avoid:
- Personal social media (Facebook, Instagram) unless the person is a public figure
  and the content is professionally relevant
- Unverified biographical claims
- Gossip, rumor, or anonymous commentary
- Outdated information presented as current (always note dates)

---

## Meeting Prep Format (REQUIRED when context is meeting prep)

When the profile is for meeting preparation, end with a structured meeting prep
section:

### Meeting Prep Brief

**Who:** [Name, Title, Organization]
**Context:** [Why you're meeting, what's the relationship]

**3 things to know:**
1. [Most important thing about this person for this meeting]
2. [Second most important]
3. [Third most important]

**Conversation starters:**
- [Topic they care about that's relevant to your meeting]
- [Recent accomplishment or activity you can reference]
- [Shared connection or common ground]

**Watch for:**
- [Communication style note - e.g., "prefers data over narratives"]
- [Known priorities or pet peeves relevant to the conversation]
- [Decision-making style - e.g., "consensus builder" or "decisive, wants options"]

**Don't:**
- [Anything to avoid based on their public positions or known preferences]

---

## Output Structure for Synthesis

1. **One-line summary** - who is this person in one sentence? Role, organization,
   and what they're known for.
2. **Career narrative** - 2-3 paragraphs telling the story of their career. Not a
   resume - a narrative that explains how they got where they are and what drives them.
3. **What they care about** - based on their public voice: key topics, positions,
   and priorities. What would they want to talk about?
4. **Network and influence** - key affiliations, board seats, investment activity,
   and who they're connected to that matters for the user's context.
5. **Recent activity** - what they've been doing in the last 6 months.
6. **Meeting prep brief** - (if context is meeting prep) the structured brief above.
7. **Open questions** - what we couldn't find or verify. What the user should ask
   directly.

---

## Common Pitfalls

- **Resume format.** A chronological list of roles is not a profile. Tell the story
  of who this person is and what drives them.
- **Ignoring their own words.** The best signal of what someone cares about is what
  they choose to write and talk about publicly. Prioritize first-person sources.
- **Stale information.** A 2019 interview may not reflect 2026 views. Always check
  for recent activity and note the dates of sources.
- **Over-indexing on titles.** A person's influence and priorities often don't match
  their title. A "VP of Strategy" might be focused on operations; a "Director" might
  be the real decision-maker.
- **No connection points.** A profile without conversation starters or common ground
  fails the meeting prep use case. Always end with actionable advice for the interaction.
