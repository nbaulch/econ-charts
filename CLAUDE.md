# Economic Charts

## What this is

A personal website of curated charts on the U.S. economy, built from public data. It will be organized into a small number of topics, each telling a story mainly through which charts are shown, in what order, and how they are titled, not through long written commentary. Each topic should stay small: a handful of charts at most, ideally one or two that carry the argument. Being selective matters more than being comprehensive.

The first topic is the AI economy: what AI is and is not doing to the U.S. economy right now. Other topics, such as inflation, will follow once the first one works. Build the site so adding a topic later is straightforward, but don't build for topics that don't exist yet.

I'm a macroeconomist. I know the data and the economics well. I'm less experienced with web development and production engineering, so explain tradeoffs there plainly and don't assume I'll catch problems in that part of the stack.

## Why it exists

Much of the best analysis in this area is published once, as a blog post or a Fed note, and then goes stale. Part of the site's value is keeping a few of those analyses current, with credit to the original authors. The rest is original charts where the public conversation is getting the numbers wrong or missing context. The site doesn't need to be only one of those.

## First topic: the AI economy storyline

This is a working hypothesis, not a conclusion. If refreshed data stops supporting part of it, that's worth telling me, not smoothing over.

- The AI buildout is adding meaningfully to demand, though less than headline claims once imported equipment is netted out.
- Adoption is real but thin, and concentrated in large firms. Firm-level, employment-weighted, and worker-level surveys give very different numbers, mostly because of who they count.
- Labor market effects so far show up as fewer young workers entering AI-exposed occupations, not as layoffs.
- The recent productivity acceleration is mostly firms using existing capital harder, not AI-driven efficiency gains. TFP is roughly flat.
- Electricity is the physical constraint, and its effects are regional rather than national.

## Chart candidates

These are the analyses I've been considering. Treat them as starting points. Verify sources, figures, and URLs yourself before relying on them.

- **AI investment's contribution to real GDP growth**, gross versus net of imported computers and semiconductors.
  - Related work: Federal Reserve FEDS Note on publicly available AI data (July 2026), ING THINK (August 2026), St. Louis Fed On the Economy (January 2026).
  - Data: BEA NIPA investment detail, Census trade data, Census construction spending.
- **AI adoption across denominators**: Census BTOS firm share, BTOS employment-weighted, and the Real-Time Population Survey worker share.
  - Related work: Allen, FEDS Note, April 2026.
  - Known break: BTOS changed its AI question wording in November 2025.
- **Employment of young workers by occupational AI exposure**, from CPS microdata.
  - Related work: Dallas Fed, January 2026.
  - Lower priority because the Stanford and ADP Canaries dashboard already updates monthly.
- **Electricity demand growth and state-level retail prices** in data center states versus the rest.
  - Data: EIA.
- **Labor productivity versus utilization-adjusted TFP**, showing the utilization contribution. This is the first chart, in `charts/productivity-decomposition/`.
  - Related work: Ernie Tedeschi, Stripe Economics, July 2026.
  - Data: BLS productivity, SF Fed (Fernald) TFP.
- **Industry AI adoption versus labor productivity growth**, before and after removing 2016 to 2019 trends. Set aside: it answers a narrower cross-sectional question.
  - Related work: same Tedeschi post.
  - Data: BTOS, Chicago Fed industry productivity.

## How I want to work

- Start with one chart and get it right before building a framework around it.
- When maintaining someone else's analysis, reproduce their published numbers for their original period before extending it. If you can't match them, stop and tell me what differs.
- Each chart should have a written spec: sources, series identifiers, transformations, vintage handling, and known breaks. The spec is what makes refreshes reliable and reviewable.
- Refreshes should report what changed: new data, revisions, methodology breaks, and results that moved enough to matter. I review before anything is published.
- Credit and link the original analysis on every chart built from someone else's work.
- Prefer boring, durable choices for data and hosting. This is a side project and needs to survive long gaps between sessions.

## Constraints

- Public data only. No employer data, tools, or accounts, including work Copilot credits.
- Nothing publishes without my review.
- I prefer to work in R.

## Repo layout

```
R/                      fetch_<agency>_<dataset>() functions, one file per agency
charts/<chart-name>/
  spec.md               sources, series IDs, transformations, vintages, breaks, decision log
  build.R               fetch, transform, plot, top to bottom
  data/                 small dated snapshots of fetched data (committed)
  output/               chart image (rebuilt, not committed) and plotted values as CSV (committed)
cache/                  large raw downloads (not committed)
```

- Organize by chart. Code moves to `R/` only when a second chart needs it.
- Use `tidyusmacro` (CRAN) for BLS, BEA NIPA, and FRED. Write `fetch_*` functions only for sources it doesn't cover.
- No topic folders until the site exists. A topic is a page that lists charts in order.
- No `legacy/`, `_backup`, `_v2`, or `_old` files. Git is the history.
- Every chart caption names the source and the series identifiers.

## Code style

The standard is a repo Hadley Wickham would be proud of: well thought out, functional, organized, and easy to read. Over-engineered code is a failure, not a safe default.

- Follow the [tidyverse style guide](https://style.tidyverse.org/). Use tidyverse packages and idioms (dplyr, tidyr, purrr, readr, ggplot2) unless there's a clear reason not to.
- Name objects and functions so a reader can tell what they hold or do without a comment: `snake_case`, nouns for data, verbs for functions.
- Functions that pull raw data are named for their source, as `fetch_<agency>_<dataset>()`: `fetch_census_btos()`, `fetch_bls_productivity()`. The agency prefix gives an unfamiliar acronym context and groups fetchers by source. A survey usually covers more than one topic, so the name shouldn't claim a single use.
- Everything after the fetch step is named for what it contains, not where it came from: `adoption_by_industry`, `productivity_growth`. Acronyms a general economics reader knows on sight (`gdp`, `cpi`, `tfp`) are fine anywhere.
- Write small, pure functions that take data and return data. Build steps with pipes, not intermediate `df1`, `df2`, `tmp`.
- Keep code tight. No speculative abstraction, config layers, wrapper functions around a single call, or defensive checks for cases that can't happen. Add structure only when a second real use shows up.
- Comment why, not what. No boilerplate headers, no comments restating the code.
- Delete dead code rather than commenting it out.
- If a simpler version would do the same job, write the simpler version.

## Environment notes

- R is not preinstalled in the cloud container, but `apt-get install -y --no-install-recommends r-base-core` works (R 4.3.x as of September 2026). The container is ephemeral, so this has to be repeated each session unless it goes into the environment's setup script.
- Keep data pulls scripted and reproducible. Don't commit hand-edited data.

## AI features I'm interested in, not yet decided

- A refresh agent that watches release calendars, updates charts from their specs, and summarizes what changed and whether it strengthens or weakens the storyline.
- Drafted annotations that I rewrite before publishing.

Propose designs when we get there, but don't build these before the first chart works.

## Writing style for anything published

Plain, measured, declarative. No em dashes as punctuation for effect, no stacked lists of three for rhythm, no marketing language. Chart titles should be accurate before they're catchy.

## Open questions

- Hosting and stack
- How to handle data vintages and revisions
- Whether and how to put charts in a shared visual style

Ask me about these when they become relevant rather than deciding them silently.
