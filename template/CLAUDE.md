# {{ project_name }} — Claude Code Context

## Stack
- ASP.NET Core {{ dotnet_version }} / Minimal APIs
{% if use_efcore %}- Entity Framework Core ({{ db_provider | replace('sqlserver','SQL Server') | replace('postgres','PostgreSQL') | replace('sqlite','SQLite') }}){% endif %}
{% if use_mediatr and architecture == 'clean' %}- MediatR (CQRS pattern){% endif %}
{% if test_framework == 'xunit' %}- xUnit + FluentAssertions{% elif test_framework == 'nunit' %}- NUnit + FluentAssertions{% elif test_framework == 'mstest' %}- MSTest + FluentAssertions{% endif %}
{% if fake_data_lib == 'bogus' %}- Bogus (fake data generation){% elif fake_data_lib == 'autofixture' %}- AutoFixture (convention-based test data){% endif %}
{% if use_testcontainers %}- Testcontainers (real database in acceptance tests){% endif %}
- GitHub: https://github.com/{{ github_org }}/{{ project_slug }}

## Architecture: {{ architecture | title }}
{% if architecture == 'clean' %}
### Layer Boundaries (enforce strictly)
| Layer | Path | Allowed dependencies |
|---|---|---|
| Api | `src/{{ project_slug }}.Api/` | Application only |
| Application | `src/{{ project_slug }}.Application/` | Domain only |
| Domain | `src/{{ project_slug }}.Domain/` | None |
| Infrastructure | `src/{{ project_slug }}.Infrastructure/` | Application, Domain |

**Rule:** No skipping layers. Api never touches Infrastructure directly.
{% elif architecture == 'vertical' %}
### Feature Structure
- `src/Features/{FeatureName}/` — self-contained feature slices
- `src/Shared/` — cross-cutting concerns only
- Each feature owns its endpoint, handler, validator, and tests
{% else %}
### Project Structure
- `src/{{ project_slug }}/` — single project
- `tests/{{ project_slug }}.Tests/` — all tests
{% endif %}

{% if testing_approach == 'layered' %}
## Testing Philosophy — Layered Testing (Swiss Cheese Model)

No single test layer catches everything. We stack layers so gaps in one are covered by another.

| Layer | What it tests | Runs when |
|---|---|---|
| **Acceptance** | Business requirements via public API (black box, real deps) | Pre-merge (CI) |
| **Unit** | Edge-case logic only (serialization, crypto, domain rules) | Pre-merge (CI) |
| **Integration** | Live environment wiring and config against real infra | Post-deploy (staging) |
| **Synthetic** | Happy-path user journeys across systems in production | Post-deploy (prod) |

### Key Principles
- **Bias toward acceptance tests.** They validate behavior, not implementation — enabling safe refactors.
- **Black-box by default.** Tests interact through HTTP endpoints or public method signatures. No mocking internals.
{% if use_efcore and use_testcontainers %}- **Real database in acceptance tests.** Never mock EF Core — use Testcontainers to spin up a real {{ db_provider | replace('sqlserver','SQL Server') | replace('postgres','PostgreSQL') | replace('sqlite','SQLite') }} instance.
{% elif use_efcore %}- **Real database in acceptance tests.** Never mock EF Core — use an in-memory provider or Testcontainers.{% endif %}
- **Test one thing at a time.** Declarative names: `Should_ExpectedBehavior_WhenStateUnderTest`.
{% if fake_data_lib == 'bogus' %}- **Randomize test data.** Use `Bogus` — hardcoded values hide bugs.
{% elif fake_data_lib == 'autofixture' %}- **Randomize test data.** Use `AutoFixture` — hardcoded values hide bugs.
{% elif fake_data_lib == 'none' %}- **Vary test data.** Avoid hardcoded magic values where possible — they hide bugs.{% endif %}
- **Deep-object equality.** Prefer `.Should().BeEquivalentTo()` over many individual assertions.
- **If it's hard to test, it's hard to integrate.** Simplify the design, don't complicate the test.
{% else %}
## Testing Philosophy — Test Pyramid

Follow the traditional test pyramid: broad base of unit tests, fewer integration tests, fewest end-to-end tests.

| Layer | What it tests | Runs when |
|---|---|---|
| **Unit** | Individual classes/methods in isolation (mock dependencies) | Pre-merge (CI) |
| **Integration** | Component interactions with real or in-memory dependencies | Pre-merge (CI) |
| **End-to-End** | Full request pipeline through the API | Pre-merge (CI, selective) |

### Key Principles
- **Unit tests are the foundation.** Every public method should have unit test coverage.
- **Mock external dependencies** in unit tests — use interfaces and DI for testability.
{% if use_efcore %}- **Integration tests** validate EF Core queries against a real or in-memory database.{% endif %}
- **Test one thing at a time.** Declarative names: `MethodName_StateUnderTest_ExpectedBehavior`.
{% if fake_data_lib == 'bogus' %}- **Use `Bogus`** for generating test data — reduces boilerplate and catches edge cases.
{% elif fake_data_lib == 'autofixture' %}- **Use `AutoFixture`** for generating test data — convention-based, minimal setup.{% endif %}
- **Deep-object equality.** Prefer `.Should().BeEquivalentTo()` over many individual assertions.
{% endif %}

## Build & Verify Commands
```bash
dotnet build --no-incremental          # must pass before task complete
dotnet test --no-build                 # must be green before PR
dotnet format --verify-no-changes      # style gate
```

## Agent Team Rules
- **Always** check the TaskList before claiming new work
- **Always** run `dotnet build` before marking a task done
- **Always** run `dotnet test` and confirm green before closing
- Implementer and test-writer coordinate on API contracts **first**
- Never modify: `.env`, `appsettings.Production.json`, `*Migrations/*.cs`
- Branch convention: `feature/issue-{number}-{short-description}`
- PR title: `[#{number}] Short description — closes #{number}`
- When working as a teammate, message the lead when blocked, not stuck silently

## GitHub Workflow
```bash
# Pull an issue
gh issue view {number} --json title,body,labels,comments

# Create a branch
git checkout -b feature/issue-{number}-{slug}

# Open a PR
gh pr create --title "[#{number}] {title}" --body "Closes #{number}" --draft
```

## Files Off-Limits to Agents
- `.env` / `.env.*`
- `appsettings.Production.json`
- `**/Migrations/**` (agents may generate migrations but not hand-edit them)
- `**/*.pfx`, `**/*.key`, `**/*.p12`
