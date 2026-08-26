# CodeIntegrity Status

The status page for CodeIntegrity services, published at
**<https://status.codeintegrity.ai>**.

Built with [Hugo](https://gohugo.io) and the
[cState](https://github.com/cstate/cstate) theme (vendored as a git submodule),
and deployed to GitHub Pages by
[`.github/workflows/static.yml`](.github/workflows/static.yml) on every push to
`master`.

## Local development

```bash
git clone --recursive https://github.com/codeintegrity-ai/status.git
cd status
hugo serve
```

If you cloned without `--recursive`, fetch the theme with
`git submodule update --init --recursive`.

The site build output (`public/`) is **not** committed — CI builds it from
source. Use the same Hugo version CI pins (`HUGO_VERSION` in the workflow).

## Posting an incident

Incidents are Markdown files in `content/issues/`. Create one per incident:

```bash
hugo new content issues/2026-08-26-api-latency.md
```

```markdown
---
title: Elevated API latency
date: 2026-08-26 14:30:00
resolved: false
severity: disrupted
affected:
  - Dashboard
section: issue
---

We are investigating elevated latency on the dashboard.
```

- `severity` is one of `notice`, `disrupted`, or `down`.
- `affected` entries must match a system `name` in [`config.yml`](config.yml).
- Set `resolved: true` and add a `resolvedWhen` timestamp to close it out.
- **Dates must be UTC** — relative times ("5 min ago") are computed from them.

Post follow-up updates newest-first in the body, stamping each with the `track`
shortcode so it gets its own timestamp:

```markdown
*Resolved* - Latency is back to baseline. {{< track "2026-08-26 15:10:00" >}}

*Investigating* - We are looking into it. {{< track "2026-08-26 14:30:00" >}}
```

## Configuration

[`config.yml`](config.yml) defines the monitored systems, categories, colors,
and page metadata. Two settings are load-bearing and easy to break:

- `enableCustomHTML: true` — required for
  [`layouts/partials/custom/meta.html`](layouts/partials/custom/meta.html),
  which emits the brand icon `<link>` tags. cState renders no icon tags of its
  own, so turning this off silently drops every favicon.
- `googleAnalytics: UA-00000000-1` — this placeholder is cState's *disabled*
  sentinel, not a stale ID. Removing the key makes the theme inject a GA script
  with an empty tracking ID.

## Brand assets

The wordmark and icons in [`static/`](static/) are generated in the
`codeintegrity-fe` repo under `brand-assets/` (`pnpm generate:all`). Do not
hand-edit them here — regenerate upstream and copy the outputs over:

| `static/` file | Source in `codeintegrity-fe` |
| --- | --- |
| `logo.svg` | `public/brand/logos/codeintegrity-wordmark-light.svg` |
| `favicon.ico`, `favicon.svg` | `brand-assets/assets/logo/output/` |
| `apple-touch-icon.png` | `brand-assets/assets/logo/output/apple-icon.png` |

`logo.png` and the `favicon-*.png` sizes are rasterized from the SVGs above.

## Vendored theme overrides

`layouts/` carries copies of five cState templates, each patched with a single
fix that config cannot reach:

| Override | Fix |
| --- | --- |
| `partials/meta.html` | `.Site.LanguageCode` → `.Site.Language.Locale` |
| `index.json`, `index.xml`, `_default/list.xml` | same |
| `partials/index/summary.html` | RSS link `{{ .Site.BaseURL }}/index.xml` → `absURL`, which was rendering a doubled slash |

`.Site.LanguageCode` was deprecated in Hugo v0.158.0, so the build would have
broken outright on a future Hugo bump. Both defects are already fixed on the
theme's unreleased `v7` branch — **these overrides are a bridge, and should be
deleted once v7 ships**, not carried forward.

A copied template silently goes stale the moment upstream edits the original,
so CI guards them:

```bash
./scripts/check-theme-overrides.sh
```

It records the upstream blob SHA each override was copied from and fails the
build when `themes/cstate` no longer matches, printing the upstream diff. After
re-syncing an override, re-baseline with `--update`. Do not hand-edit the
vendored files — re-copy from the theme and re-apply the one-line fix named in
each file's header.

## Updating the theme

```bash
git submodule update --remote themes/cstate
./scripts/check-theme-overrides.sh   # tells you if a vendored override drifted
hugo serve                           # verify, then commit the submodule pointer
```

If the check reports drift, re-copy the affected template from the theme,
re-apply the one-line fix named in its header, then run
`./scripts/check-theme-overrides.sh --update`.
