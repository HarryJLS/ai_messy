# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a collection of AI agent workflows and development guides (primarily in Chinese). It contains:

- **Agent Workflow** (`workflow/plan-*.md`) - A structured TDD-based development workflow with task management
- **Code Review** (`workflow/code-review.md`) - Diff-based code review with language-specific checklists
- **Code Fixer** (`workflow/code-fixer.md`) - Auto-fix code style issues (small fixes auto, big changes need confirmation)
- **WorkTeam Workflow** (`common/workTeam.md`) - A role-based product development pipeline
- **Skills** (`skills/`) - Claude Code skills for the Agent workflow
- **Testing Guides** (`common/`) - Spock testing guides for Java/Groovy and Go

## Agent Workflow

The primary workflow for structured development using TDD.

**Workflow files:**
- `workflow/plan-init.md` - Initialize project
- `workflow/plan-next.md` - Execute tasks (TDD cycle)
- `workflow/plan-log.md` - Manual logging
- `workflow/plan-archive.md` - Archive completed work

**Core commands:**

| Command | Purpose |
|---------|---------|
| `/plan-preview` | Pre-research technical solution, output `task.md` for `/plan-init` |
| `/plan-init` | Initialize project, create `features.json` and `dev-YYYY-MM-DD.log` |
| `/plan-next` | Execute next pending task using TDD cycle (RED → GREEN → COMMIT) |
| `/plan-log` | Manually log non-task progress (architecture decisions, urgent fixes) |
| `/plan-archive` | Archive completed work to `archives/YYYY-MM-DD-HHMMSS/` |
| `/dev-team` | Full orchestration: preview + init + next + simplifier + fixer |

## Dev Team (Agent Team Orchestration)

See `skills/dev-team/SKILL.md` for full specification.

Multi-agent team that orchestrates the full development pipeline automatically:

**Team roles:**

| Role | Agent | Responsibility |
|------|-------|----------------|
| lead | self | Orchestration, user communication, decision relay |
| architect | general-purpose (dontAsk) | Plan preview + project init |
| developer | general-purpose (bypassPermissions) | TDD task execution loop |
| polisher | general-purpose (bypassPermissions) | Code simplification + style fix |

**Pipeline:** Plan Preview → Project Init → TDD Dev Loop → Code Polish → Report

**Cross-project reference support:**
- Phase 0: lead identifies reference project path from user input
- Phase 1: architect explores reference project code, writes key file paths into `task.md` references
- Phase 3: developer reads references automatically via plan-next's reference learning flow (locate → analyze → trace calls → adapt)

**Auto-resume:** Re-running `/dev-team` detects existing files (`task.md`, `features.json`) and skips to the appropriate phase.

## Code Review & Fixer

| Command | Purpose |
|---------|---------|
| `/code-review` | Review code changes, generate review report |
| `/code-fixer` | Auto-fix code style issues (preserves variable names) |

**Supported standards:**
- Java: 阿里巴巴 Java 开发规范
- Go: 字节跳动 Go 开发规范
- Frontend: React/TypeScript best practices
- Backend: Python/FastAPI best practices

### Key Files
- `features.json` - Single source of truth for tasks (array of task objects with `passes: boolean`)
- `dev-YYYY-MM-DD.log` - Unified development log (all entries appended chronologically with structured tags)

### Task Execution Flow (plan-next)
1. **READ** - Find first task with `passes: false`
2. **EXPLORE** - Analyze existing code (skip for new features)
3. **PLAN** - Review steps, acceptance criteria, confirm boundaries
4. **RED** - Write failing tests first
5. **IMPLEMENT** - Minimal code to pass tests
6. **GREEN** - Verify all tests pass, check acceptance criteria
7. **COMMIT** - Set `passes: true`, write final log

### Design Principles
- Anti-forgetting: Restore context by searching dev-YYYY-MM-DD.log for task entries
- Anti-scope-creep: JSON defines scope, logs provide detail
- Precision: Only change what needs changing, never touch unrelated code
- Senior developer perspective: Consider reusability, extensibility, robustness

## Testing Guidelines

### Java/Groovy (Spock Framework)
See `common/spock-test-guide.md` for complete reference.

```groovy
// BDD structure: given-when-then
def "test description"() {
    given: "setup"
    def mock = Mock(Service)

    when: "action"
    def result = target.method()

    then: "verification"
    result == expected
}
```

Key patterns:
- Mock with `Mock(Interface)`
- Stub returns with `mock.method(_) >> value`
- Verify calls with `1 * mock.method(_)` in then block
- Data-driven tests with `where:` block and `@Unroll`

### Go (Mockey + Testify)
See `common/go_test_spock.md` for complete reference.

```go
// Table-driven tests with runtime mocking
func TestMethod(t *testing.T) {
    defer mockey.OffAll()

    tests := []struct{
        name string
        // ... fields
    }{
        // test cases
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            mockey.Mock(SomeFunc).To(...).Build()
            // test logic
        })
    }
}
```

**Required flags for Go tests with Mockey:**
```bash
go test -gcflags="all=-l -N" -v ./...
```

## WorkTeam Workflow (Role-Based)

A product development pipeline with 5 specialized roles:

1. `/pm` - Product Manager: Collect requirements, output `prd.md`
2. `/ui` - UI Designer: Design prompts, output `ui-prompts.md`
3. `/nano` - Nano Banana: Generate UI images to `assets/`
4. `/fe` - Frontend Engineer: Build frontend
5. `/full` - Full-stack Engineer: Backend development and iteration
