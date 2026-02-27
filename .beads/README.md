# Beads - AI-Native Issue Tracking

This repository uses **Beads** (`br`) for issue tracking — a CLI-first tool that lives directly in your codebase alongside your code.

**Learn more:** [github.com/Dicklesworthstone/beads_rust](https://github.com/Dicklesworthstone/beads_rust)

## Quick Start

### Essential Commands

```bash
# Create new issues
br create "Add user authentication"

# View all issues
br list

# View issue details
br show <issue-id>

# Update issue status
br update <issue-id> --status in_progress
br update <issue-id> --status done

# Export JSONL for git sync (then git add .beads/ && git commit)
br sync --flush-only
```

### Working with Issues

Issues in Beads are:
- **Git-native**: Stored in `.beads/` and synced like code
- **AI-friendly**: CLI-first design works perfectly with AI coding agents
- **Branch-aware**: Issues can follow your branch workflow

### Sync Workflow

`br` does not auto-commit to git. After making changes:

```bash
br sync --flush-only        # Export data to JSONL
git add .beads/             # Stage beads data
git commit -m "beads sync"  # Commit manually
```

## Companion Tools

- **beads viewer (`bv`)**: TUI/graph sidecar for visualizing the issue graph — [GitHub](https://github.com/Dicklesworthstone/beads_viewer)

## Learn More

- **Documentation**: [github.com/Dicklesworthstone/beads_rust](https://github.com/Dicklesworthstone/beads_rust)
- **Quick Start Guide**: Run `br --help`

---

*Beads: Issue tracking that moves at the speed of thought* ⚡
