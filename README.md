# Causari Guard — GitHub Action

The first privacy-preserving causal watchdog for AI-generated code.

Drop this action into any repository that uses [Causari](https://causari.dev) and every pull request automatically gets a guard summary comment — zero configuration, zero data leaves the repository.

```yaml
- uses: croviatrust/causari-guard-action@v1
```

That's it. No API keys to manage. No cloud dashboard. No telemetry.

## What it does

Every time a pull request is opened or updated:

1. **Installs** the latest `re` binary (~2 seconds by downloading a pre-built release for your runner's exact OS and architecture).
2. **Runs** `re guard --summary` on the PR branch.
3. **Posts** a Markdown table to the PR comment thread:

   | Event | Agent | Rule | Detail |
   |---|---|---|---|
   | `a3f7b2c9` | claude | 🔴 critical without test | modified auth.ts but no test |
   | `d5e2a1b3` | claude | 🟡 missing tests | modified source but no tests |

4. **Fails CI** if alerts are found (configurable).

## Usage

### Minimal (one line)

```yaml
name: Causari Guard
on:
  pull_request:

permissions:
  contents: read
  pull-requests: write

jobs:
  guard:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: croviatrust/causari-guard-action@v1
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
```

### With options

```yaml
- uses: croviatrust/causari-guard-action@v1
  with:
    limit: 50          # scan last 50 events instead of 20
    fail-on-alert: false  # post comment but don't block merge
```

### Combine with the badge

Keep a guard badge in your README that stays green when the main branch is clean:

```markdown
![Causari Guard](.causari/guard-badge.svg)
```

Regenerate it in CI:

```yaml
- name: Update guard badge
  run: re guard --badge
- name: Commit badge
  uses: stefanzweifel/git-auto-commit-action@v5
```

## Why this exists

| Tool | Tracks | PR comment | Privacy |
|---|---|---|---|
| Codecov | test coverage | yes | sends data to cloud |
| Dependabot | dependencies | yes | sends data to cloud |
| **Causari Guard** | causal risk (auth without test, bulk edits, missing tests) | **yes** | **all local, zero external API** |

No other tool can tell you that an agent modified `auth.rs` without touching any test file. Causari Guard can, because it reads the causal ledger — not just the diff.

## License

Business Source License 1.1 → Apache 2.0 after four years.
