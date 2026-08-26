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

## Updating the theme

```bash
git submodule update --remote themes/cstate
hugo serve   # verify, then commit the submodule pointer
```
