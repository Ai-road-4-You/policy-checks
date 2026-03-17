# Copilot Instructions — OpenClaw Gateway

## Project Overview

OpenClaw is a self-hosted AI agent gateway that connects to WhatsApp, Telegram, and voice channels. It runs on Node.js 22 LTS, deployed via Docker (multi-stage build, bookworm-slim) or macOS LaunchAgent. The agent has 272 installed skills, a markdown-based memory system, and uses GitHub Copilot/GPT-5.2 as its primary model.

- **Runtime**: Node.js 22 LTS
- **Config**: `openclaw.json` (secrets + main config, gitignored), `.env` (Docker overrides)
- **Skills**: `workspace/skills/` — 272 skills, ~60% markdown-only (SKILL.md), rest have code
- **Package manager**: pnpm (for skills with dependencies)
- **Container**: Docker + docker-compose, non-root UID 1001, tini init
- **CI/CD**: GitHub Actions (`docker-build.yml`)
- **Monitoring**: `scripts/monitor-v4.sh` (continuous health checks)

## Architecture

```
~/.openclaw/
├── openclaw.json           # Main config (gitignored — secrets)
├── Dockerfile              # Multi-stage build (builder + runtime)
├── docker-compose.yml      # Container orchestration + Watchtower
├── Makefile                # Convenience targets (build, up, down, etc.)
├── workspace/              # Agent workspace
│   ├── SOUL.md             # Agent personality/identity
│   ├── USER.md             # User profile
│   ├── MEMORY.md           # Long-term curated memory
│   ├── HEARTBEAT.md        # Proactive checklist
│   ├── TOOLS.md            # Tool configuration notes
│   ├── AGENTS.md           # Operating rules
│   ├── skills/             # 272 installed skills
│   └── memory/             # Daily logs (YYYY-MM-DD.md)
├── credentials/            # WhatsApp/Telegram sessions (gitignored)
├── identity/               # Device auth (gitignored)
├── agents/                 # Agent sessions
├── cron/                   # Scheduled jobs (jobs.json)
├── scripts/                # Management scripts (bash)
│   ├── docker-ops.sh       # Docker CLI (build/up/down/logs/status/backup)
│   ├── monitor-v4.sh       # Continuous health monitor
│   ├── backup.sh           # Automated backup with rotation
│   ├── healthcheck.sh      # Quick health probe
│   └── skill-audit.sh      # Skill quality checker
├── canvas/                 # Canvas UI (HTML)
├── logs/                   # Runtime logs
└── media/                  # Inbound media (voice notes, images)
```

## Code Style & Conventions

### Shell Scripts

- Use `set -euo pipefail` (or `set -uo pipefail` for monitors)
- Color-coded logging with `log()`, `warn()`, `err()` functions
- Preflight checks before operations
- Trap handlers for cleanup
- Compatible with both Docker and macOS LaunchAgent environments

### Skills (SKILL.md)

- Frontmatter: `name`, `description`, `argument-hint`
- kebab-case directory names
- Markdown-only skills need only `SKILL.md`
- Code skills may include `package.json`, scripts, and Node.js code
- Use pnpm for dependency installation

### Configuration

- All API keys in `openclaw.json` `env` block (21 keys)
- LaunchAgent processes do NOT inherit `~/.zshrc` — keys must be in `openclaw.json env`
- Config schema is strict — unknown keys block reloads
- Cron jobs require `schedule.kind` and `payload.kind` fields

### Language

- User speaks Swedish, mixes with English technical terms
- Code comments and technical output in English
- Agent responses default to Swedish

## Important Constraints

### Security

- **Malware history**: 10 malicious skills were found and removed (C2: 91.92.242.30, glot.io payloads)
- Always scan new skills for: C2 patterns, `curl|bash`, base64 obfuscation, raw IPs, password-protected zips
- API keys exist in git history (commits 96b34719, b86f076c, d2b27ae6) — repo is private
- `sandbox.mode: off` — skills run with full system access
- Container hardened: cap_drop ALL, no-new-privileges, pids_limit 256, loopback-only

### Known Issues

- Telegram: BOT_COMMANDS_TOO_MUCH (272 skills > 100 command limit)
- WhatsApp: periodic 408/428/503 reconnects are normal (Baileys behavior)
- `sharp` dependency installed with `--ignore-scripts` — image processing may be affected
- 149 markdown-only skills work as knowledge but inflate Telegram command count

## Workflow

### Build & Deploy

```bash
make build        # Build Docker image
make up           # Start gateway
make down         # Stop gateway
make status       # Health check
make deploy       # Build + start
make quick        # Validate + build + start
```

### Gateway Management (without Docker)

```bash
npm install -g openclaw@2026.3.8
openclaw gateway --port 18789
```

### Monitoring

```bash
./scripts/monitor-v4.sh    # Continuous monitor (600s interval)
./scripts/healthcheck.sh   # Quick health probe
```

### Backup

```bash
./scripts/backup.sh        # 7 daily + 4 weekly rotation
```

### Cron Jobs (4 active)

- **08:00 daily**: Daily summary → WhatsApp self-chat
- **18:00 Mon-Fri**: Evening check-in
- **02:00 Wed+Sat**: Memory maintenance
- **03:00 Monday**: Weekly security scan

## Agent Orchestration

OpenClaw uses a multi-agent orchestration system for autonomous operation. The orchestrator coordinates specialized agents through workflows with gates, retries, and rollback.

### Agent Hierarchy (29 agents)

```
orchestrator          ← Master coordinator: decomposes goals, executes pipelines
├── preflight         ← Pre-flight validation gate (always first)
├── plan              ← Creates implementation plans
├── architect         ← Architecture design & validation
├── developer         ← Implementation (code, scripts, skills)
├── security          ← Security gate (malware, C2, container audit)
├── tester            ← Validation gate (syntax, config, health)
├── reviewer          ← Quality gate (conventions, correctness)
├── deploy            ← Docker/LaunchAgent deployment
├── rollback          ← Undo registry & emergency recovery
├── monitor           ← Post-deploy health verification
├── notifier          ← Alert dispatch (WhatsApp/Telegram)
├── scheduler         ← Cron job management
├── skill-builder     ← Skill creation & management
├── refactor          ← Code restructuring
├── performance       ← Profiling & optimization
├── troubleshoot      ← Incident response
├── docs              ← Documentation maintenance
├── verification      ← Independent change validation (re-runs, PASS/FAIL)
├── ci                ← CI/CD pipeline management (GitHub Actions)
├── dependencies      ← Dependency management (pnpm audit, supply chain)
├── secrets           ← Secrets hygiene (21 API keys, rotation, leak scan)
├── compliance        ← Policy enforcement (6 domains)
├── container         ← Dockerfile/image security & optimization
├── observability     ← Logging, metrics, tracing, alerting
├── incident          ← Incident response playbooks (P1-P4)
├── api               ← Gateway API management (port 18789)
├── integration       ← External systems (WhatsApp/Telegram/voice)
└── dx                ← Developer experience & tooling
```

### Standard Workflows

| Workflow           | Pipeline                                                                                   | Risk     |
| ------------------ | ------------------------------------------------------------------------------------------ | -------- |
| deploy-upgrade     | preflight → backup → plan → develop → test → security → review → deploy → monitor → notify | High     |
| security-scan      | preflight → security (4 phases) → notify                                                   | Low      |
| skill-install      | preflight → security → create → test → review → install deps → notify                      | Medium   |
| config-change      | preflight → backup → plan → modify → validate → restart → monitor → notify                 | Medium   |
| maintenance        | preflight → security → audit → memory → performance → cleanup → backup → notify            | Low      |
| hotfix             | preflight → backup → fix → test → deploy → monitor → notify                                | High     |
| rollback-emergency | locate backup → stop → restore → redeploy → notify                                         | Critical |
| full-audit         | preflight → environment → security → skills → deps → performance → notify                  | Low      |

### Gates & Error Handling

Every pipeline step has a **gate** (verification condition) and a **retry policy**. On failure:

1. Retry if transient (network, timeout) — max 2-3 retries with backoff
2. Rollback if retry fails — undo operations in reverse order
3. Notify on all outcomes (success, failure, rollback)
4. Never leave the system in a broken state

### Key Files

- `.github/copilot/agents/` — 29 agent definitions
- `.github/copilot/prompts/` — 40 prompt templates
- `.github/copilot/workflows/README.md` — Workflow definitions
- `.github/copilot/lib/conventions.md` — Shared coding conventions
- `.github/copilot/AUTONOMY-GUARDRAILS.md` — Mandatory rules for all agents
- `.github/skills/` — 36 skill definitions (with companion scripts)
