# Branching & Git Workflow

We use a **two-tier** branching model so six people can work in parallel without
breaking each other's code.

```
main      → stable, submission-ready code only
  ▲
  │  (merge only when develop is tested & stable)
develop   → shared integration branch (everyone merges here)
  ▲   ▲   ▲
  │   │   │
feat/<name>-<task>   → one branch per person, per task
```

**Golden rule:** never commit directly to `main` or `develop`. Always work on
your own `feat/...` branch and merge in through a Pull Request.

---

## Branch naming

| Type | Pattern | Example |
|------|---------|---------|
| Feature | `feat/<name>-<task>` | `feat/evan-theme-switcher` |
| Bug fix | `fix/<name>-<task>`  | `fix/waiying-balance-rounding` |
| Docs    | `docs/<name>-<task>` | `docs/wanting-report-format` |

Keep names short, lowercase, and hyphenated.

---

## Daily workflow

### 1. Start a task — branch off the latest `develop`
```bash
git checkout develop
git pull origin develop          # get everyone's latest work
git checkout -b feat/yourname-task
```

### 2. Work, then commit your changes
```bash
git add .
git commit -m "Add X to Y"
```

### 3. Push your branch
```bash
git push -u origin feat/yourname-task
```

### 4. Open a Pull Request → into `develop`
- On GitHub, open a PR from your `feat/...` branch into **`develop`**.
- Ask one teammate to review and approve, then merge.
- Delete the feature branch after merging (GitHub offers a button).

### 5. Keep your branch up to date (if others merged first)
```bash
git checkout develop
git pull origin develop
git checkout feat/yourname-task
git merge develop                # resolve any conflicts here, not on develop
```

---

## Releasing to `main`

Only the Project Manager (Lik) or a chosen lead merges `develop` → `main`, and
only when the app builds, tests pass, and the team agrees it's stable:

```bash
git checkout main
git pull origin main
git merge develop
git push origin main
```

Tip: protect `main` on GitHub (Settings → Branches → add a rule) so it can only
be updated through a reviewed Pull Request.

---

## Before you push — quick checklist
- [ ] App still runs: `flutter run`
- [ ] Static analysis clean: `flutter analyze`
- [ ] Tests pass: `flutter test`
- [ ] You branched off the **latest** `develop`
- [ ] PR targets `develop`, not `main`
