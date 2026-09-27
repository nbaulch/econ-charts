# Economic Charts

## What this is

A personal website of curated charts on the U.S. economy, built from public data. It will be organized into a small number of topics, each telling a story mainly through which charts are shown, in what order, and how they are titled, not through long written commentary. Each topic should stay small: a handful of charts at most, ideally one or two that carry the argument. Being selective matters more than being comprehensive.

The first topic is the AI economy: what AI is and is not doing to the U.S. economy right now. Other topics, such as inflation, will follow once the first one works. Build the site so adding a topic later is straightforward, but don't build for topics that don't exist yet.

I'm a macroeconomist. I know the data and the economics well. I'm less experienced with web development and production engineering, so explain tradeoffs there plainly and don't assume I'll catch problems in that part of the stack.

## Why it exists

Much of the best analysis in this area is published once, as a blog post or a Fed note, and then goes stale. Part of the site's value is keeping a few of those analyses current, with credit to the original authors. The rest is original charts where the public conversation is getting the numbers wrong or missing context. The site doesn't need to be only one of those.

## First topic: the AI economy storyline

This is a working hypothesis, not a conclusion. If refreshed data stops supporting part of it, that's worth telling me, not smoothing over.

- The AI buildout is adding to growth, though less than headline figures suggest once imported computers are netted out. Investment in software, computers, data centers, and power has lifted real GDP growth since early 2025, from a pre-buildout contribution that was mostly software.
- Adoption is spreading but still thin among firms, and concentrated in large firms. Surveys of workers find much wider use than surveys of firms; the gap reflects both who is counted and how the question is asked.
- The recent productivity acceleration is mostly firms using existing capital and labor harder, which Tedeschi links to meeting demand for AI capacity, plus investment in computers and software, not AI-driven efficiency gains. Utilization-adjusted TFP grew strongly in 2023 and 2024 and has fallen over the past year.

## Second topic: interest rates

A working hypothesis, drafted September 2026 for review.

- Long-term Treasury yields are higher than before 2024 mostly because of a higher term premium. A decomposition can't say whether fiscal policy, Treasury supply, or AI-related borrowing is behind it.
- This year's rise mostly reflects higher expected policy rates in a strong economy, in both the Fed Board and New York Fed models. The models differ on how much the term premium added. The rise is mostly in real yields, with a smaller contribution from expected inflation.
- Big tech has become a new source of long-term debt for investors to absorb, adding about a quarter as much as Treasury in the past year after little before 2025, while Treasury's own contribution has not grown.

Charts: `charts/yield-decomposition/`, `charts/yield-rise-by-model/`, and `charts/duration-supply/` (built). Candidate: the 10-year yield split into inflation-protected yield and breakeven inflation, with the 2-year yield.

## Third topic: inflation

Started September 2026. The working hypothesis will be drafted from the charts rather than ahead of them. The debate: is underlying inflation rising, as much of the FOMC says, or are oil and tariff shocks passing through, as Robin Brooks and Mark Zandi argue, with markets pushing the Fed to hike?

Charts: `charts/inflation-measures/` and `charts/inflation-breadth/` (built; breadth reproduces Warsh's share of PCE categories rising faster than 3 percent). Planned, one question each: why PCE runs above CPI (Konczal), supply- versus demand-driven inflation (San Francisco Fed), tariffs (St. Louis Fed method, checked against the April 2026 FEDS Note), AI's contribution (software and electricity prices), and inflation expectations. Release-day tools (PCE implied by CPI and PPI, surprises) come later; surprises need a public benchmark, such as the Cleveland Fed nowcast, since consensus forecasts are proprietary.

## Chart candidates

These are the analyses I've been considering. Treat them as starting points. Verify sources, figures, and URLs yourself before relying on them.

- **AI investment's contribution to real GDP growth**, gross versus net of imported computers and semiconductors. Built in `charts/ai-investment-gdp/`, following the FEDS Note method.
  - Related work: Federal Reserve FEDS Note on publicly available AI data (July 2026), ING THINK (August 2026), St. Louis Fed On the Economy (January 2026).
  - Data: BEA NIPA investment detail, Census trade data, Census construction spending.
- **AI adoption by firm size.** Built in `charts/ai-adoption/`: the Census BTOS share of firms using AI in three size groups, weighted by Census firm counts. The earlier version across denominators (firms, workers, and one employment-weighted survey point) was dropped as hard to read; the worker share from the Real-Time Population Survey is quoted in the text.
  - Related work: Allen, FEDS Note, April 2026; Bick and coauthors, St. Louis Fed, June 2026, on question wording.
  - Known break: BTOS changed its AI question wording in November 2025. Size-class estimates exist only for the new wording.
- **Employment of young workers by occupational AI exposure**, from CPS microdata. Dropped in September 2026, with its storyline bullet, because the Stanford and ADP Canaries dashboard already tracks it monthly.
  - Related work: Dallas Fed, January 2026.
- **Electricity demand and prices by state.** Built and dropped in September 2026, because the link to AI is indirect and the investment chart already covers data centers and power. Findings, from EIA Form 861M: six states (Texas, Virginia, Ohio, Georgia, Arizona, Oregon) accounted for about three quarters of the growth in commercial electricity use from 2019 to mid-2026. Household prices rose no faster in states where demand grew fastest, matching Lawrence Berkeley National Laboratory and Brattle (2025). Data centers do raise costs through PJM's capacity market, which a state comparison can't show.
- **Labor productivity versus utilization-adjusted TFP**, showing the utilization contribution. This is the first chart, in `charts/productivity-decomposition/`.
  - Related work: Ernie Tedeschi, Stripe Economics, July 2026.
  - Data: BLS productivity, SF Fed (Fernald) TFP.
- **Industry AI adoption versus labor productivity growth**, before and after removing 2016 to 2019 trends. Set aside: it answers a narrower cross-sectional question.
  - Related work: same Tedeschi post.
  - Data: BTOS, Chicago Fed industry productivity.

## How I want to work

- Start with one chart and get it right before building a framework around it.
- When maintaining someone else's analysis, reproduce their published numbers for their original period before extending it. If you can't match them, stop and tell me what differs.
- Getting the story right matters more than matching the original, but replication is what makes a chart defensible, so deviate only with confidence. A deviation needs a reason grounded in data, not preference, and a consistency check against an independent source that the new method passes. Report how much it moves the result, keep `reproduce.R` matching the original under their method, record the deviation in the spec's decision log, and say on the chart that the method is adapted.
- Each chart should have a written spec: sources, series identifiers, transformations, vintage handling, and known breaks. The spec is what makes refreshes reliable and reviewable.
- Refreshes should report what changed: new data, revisions, methodology breaks, and results that moved enough to matter. I review before anything is published.
- Credit and link the original analysis on every chart built from someone else's work.
- Prefer boring, durable choices for data and hosting. This is a side project and needs to survive long gaps between sessions.

## Constraints

- Public data and personal tools and accounts only.
- Nothing publishes without my review.
- I prefer to work in R.

## Repo layout

```
_quarto.yml, *.qmd      the site: config and one page per topic, plus index.qmd
styles.css              site styling, matched to STYLE.md
R/                      fetch_<agency>_<dataset>() functions, one file per agency, and chart_style.R
fonts/                  bundled chart font, used by charts and the site
charts/<chart-name>/
  spec.md               sources, series IDs, transformations, vintages, breaks, decision log
  build.R               fetch, transform, plot, top to bottom
  reproduce.R           check against the original analysis, for charts that maintain someone else's work
  data/                 small dated snapshots of fetched data (committed)
  output/               chart images (wide and narrow) and CSV of the plotted series, all committed and published
cache/                  large raw downloads (not committed)
```

- Organize by chart. Code moves to `R/` only when a second chart needs it.
- Use `tidyusmacro` (CRAN) for BLS, BEA NIPA, and FRED. Write `fetch_*` functions only for sources it doesn't cover.
- A topic is one `.qmd` page that shows its charts in order. Add it to `render` and the navbar in `_quarto.yml`.
- Every chart on the site has a link to download its CSV. Under each chart, one link goes to its entry on `sources.qmd`, which holds the definitions, sources, release dates, credit links, and CSV download.
- No `legacy/`, `_backup`, `_v2`, or `_old` files. Git is the history.
- Every chart names its source and data release in the notes. Series identifiers and formulas go in the spec, not on the chart.

## Publishing

The site is https://nbaulch.github.io/econ-charts/, built with Quarto and hosted on GitHub Pages.

- `main` is protected. Every change goes through a pull request that I review and merge.
- Merging to `main` runs `.github/workflows/publish.yml`, which renders the pages and publishes them. It does not run R. Charts are rebuilt in a session and committed.
- To preview locally, run `quarto render` and open `_site/index.html`.

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

- Run scripts from the project root, for example `Rscript charts/productivity-decomposition/build.R`. Paths are relative to it.
- R packages are pinned in `renv.lock`. Run `renv::restore()` at the start of a session, and `renv::snapshot()` after adding a package.
- The cloud container is ephemeral and starts without R. `.claude/hooks/session-start.sh` runs at the start of every Claude Code on the web session and installs R, the graphics libraries `ragg` needs, Quarto 1.10.18 (matching the publish workflow), and the packages in `renv.lock`. It skips anything already installed. It installs packages as prebuilt Linux binaries from Posit rather than compiling from CRAN source, which takes seconds instead of many minutes. The lockfile itself points at plain CRAN, so it works on a Mac or Windows machine unchanged.
- On your own machine, install R and Quarto normally, then run `renv::restore()` once.
- Keep data pulls scripted and reproducible. Don't commit hand-edited data.

## AI features I'm interested in, not yet decided

- A refresh agent that watches release calendars, updates charts from their specs, and summarizes what changed and whether it strengthens or weakens the storyline.
- Drafted annotations that I rewrite before publishing.

Propose designs when we get there, but don't build these before the first chart works.

## Writing style for anything published

Plain, measured, declarative. No stacked lists of three for rhythm, no marketing language. Em dashes are fine for an aside, not for effect. Charts follow `STYLE.md`: no acronyms on a chart except ones every reader knows, such as GDP and AI, and notes define terms in plain words rather than with equations.

Write like a staff economist briefing the Treasury secretary: high level, short, and cut hard.

- **The paragraph above a chart** opens with the general point, then backs it up. Two to six sentences, each with one clear purpose and message. If a sentence is doing two jobs, split it or cut one.
- **Be factual about what is measured.** Name things for what they are. If a category is broader than its label, such as "AI investment" that includes software spending unrelated to AI, name the components instead.
- **Numbers in the text should be visible on the chart.** If a reader would wonder where a number comes from, show it on the chart or drop it. Keep precision consistent, and don't round a number up to make a point.
- **Mention a range or alternative estimate only if it changes the story.** Otherwise keep it in the spec as a refresh check.
- **Avoid words with two meanings in one paragraph**, such as "headline" for both a gross figure and GDP growth.
- **Don't repeat on the chart what the chart already shows**, such as the data's end date in the image's source line. The release date goes in the notes below the chart.
- **Notes below the chart are short definitions only.** If it matters, it goes in the paragraph.

For charts:

- **The title states the chart's message**, all of it: if the paragraph makes two points, the title carries both. Accurate before catchy.
- **One chart that tells the whole story beats two that split it.** Never publish a standalone chart of a figure the text argues is misleading.
- **Smooth the data when noise hides the story**, and use the same measure the text quotes, such as four-quarter averages.

When I ask for options, give a recommendation. When I'm unsure, show me a preview rather than describing it.

## Vintages and revisions

- Charts show the latest release of their data.
- Each fetch saves the source release as a dated file in the chart's `data/` folder, named by the source's release date when the source gives one. Git keeps the history.
- A refresh compares the new plotted CSV with the committed one and reports revisions that matter, along with new data and methodology changes. The git diff of the CSV is the record.
- Reproductions of someone else's work use the vintage closest to theirs when it is available, and say so when it isn't.

## Open questions

None right now. When a new decision about the stack, data, or publishing comes up, ask me rather than deciding it silently.
