{{!-- Template: company-identity.md
     Substitution: replace {{ORG_NAME}}, {{TEAM}}, {{ROLE}} with your org's values
     before submitting to the propose flow.
     This becomes plugins/admin/context/company-identity/context.md in your fork.
--}}
# Company identity reference

> Canonical reference for `admin` skills.
> Owner: {{ORG_NAME}} Dewey admin.

This file is the source of truth for *what {{ORG_NAME}} is and does*. Skills that need to write in the company's voice, reference company history, or introduce the company to a reader should load this file.

## One-sentence description

A single, audience-neutral statement of what {{ORG_NAME}} does and who it serves. *(Replace this with your actual positioning sentence — the seed text is intentionally generic so it is clear this is a template.)*

Example shape: "{{ORG_NAME}} is a [product type] that helps [buyer profile] [achieve outcome] without [the painful alternative]."

## Founded and stage

- **Founded:** {{YEAR_FOUNDED}}
- **Stage:** {{STAGE}} (e.g., Series A, bootstrapped, public)
- **Headcount:** {{HEADCOUNT}} approximate

## What we build

Two or three sentences on the core product or service. What does it do? What's the main interface (SaaS, API, service, marketplace)? Who operates it day-to-day?

## What we do not do

Boundaries matter as much as scope. What does {{ORG_NAME}} explicitly not do, even if asked?

- Not a [category] — explain briefly.
- Not targeting [segment] — explain briefly.

## How to use this file

Skills that load this file should use the one-sentence description verbatim when introducing the company. The "What we do not do" section is important for skills that write on the company's behalf — they should not overpromise or claim capabilities outside this scope.
