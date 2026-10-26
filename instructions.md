# MoneyHawk: Engineering Instructions

> These rules apply to every contributor, coding agent, and automated
> workflow working on MoneyHawk. They are mandatory unless the user
> explicitly authorizes an exception.

## 1. Source of Truth and Project Files

Maintain these project documents:

-   `plan.md`: Product goals, architecture, roadmap, constraints, and
    acceptance criteria. Treat as the stable project plan. Do not
    silently rewrite or replace it during implementation. If a material
    plan change is required, propose it and obtain the user's approval
    before editing.
-   `instructions.md`: These coding, security, testing, Git, and release
    rules. Do not weaken or remove rules without explicit approval.
-   `changelog.md`: Chronological record of meaningful changes,
    including date, summary, affected areas, tests, and commit/release
    reference when available.
-   `currentstate.md`: Concise description of the current implemented
    state, architecture, working features, known issues, active branch,
    build/test status, pending work, and exact next step. It must let a
    new agent understand the project without reading every source file.

Keep `changelog.md` and `currentstate.md` updated as part of meaningful
changes, preferably before committing. Do not claim a test, build,
deployment, release, or push succeeded unless its result was verified.

## 2. Core Engineering Principles

-   Prefer correctness, security, observability, and maintainability
    over premature optimization.
-   Optimize latency using measurements, not assumptions.
-   Keep the architecture modular but avoid unnecessary microservices
    and dependencies.
-   Preserve clear boundaries between mobile UI, market
    data, AI/strategy logic, risk controls, broker integration, order
    management, and persistence.
-   Use explicit types, schemas, contracts, and state transitions.
-   Handle all expected errors and uncertain outcomes deliberately.
-   Never use AI output as a substitute for deterministic validation.
-   Keep documentation aligned with the implementation.
-   Do not fabricate broker API capabilities. Verify endpoints, request
    fields, authentication, supported order types, rate limits, and data
    semantics against current official Groww documentation before coding
    against them.
-   If an implementation detail is uncertain, document the uncertainty
    and ask or investigate rather than guessing.

## 3. Git Branch and User Changes

-   Work on the existing intended branch unless the user explicitly
    authorizes a branch change.
-   Inspect `git status` and the current branch before modifying files.
-   Preserve all uncommitted user changes. Do not overwrite, discard,
    reformat, or stage unrelated work.
-   Never run destructive commands such as `git reset --hard`,
    `git clean -fd`, force push, history rewrite, or branch deletion
    without explicit permission.
-   Do not change remotes, branch protection, repository visibility, or
    access controls without explicit permission.
-   Keep commits focused and use clear, descriptive messages.
-   Never add an AI co-author trailer to commit messages.
-   Review both `git diff` and `git diff --cached` before committing.
-   Stage only files relevant to the intended change.
-   Never commit secrets, credentials, tokens, signing keys, personal
    account data, real trading records, production database files, build
    outputs, or machine-specific IDE files.
-   Ensure `.gitignore` covers platform build outputs, generated files,
    secrets, local configuration, IDE files, and test artifacts as
    applicable.
-   Push only to the configured remote and intended branch. Verify push
    success and report failures honestly.

## 4. Mandatory Build and Push Discipline

-   Compilation/build verification is mandatory before a commit or push.
-   Push after every file change that leaves the solution buildable, or
    at minimum when approximately 50 lines of production code have
    changed since the last push, whichever comes first, subject to the
    compilation rule below.
-   Never push a state that does not build. If the 50-line threshold is
    reached but the solution does not compile, the compilation
    requirement wins. Continue with the smallest coherent changes needed
    to restore a build, then test, commit, and push.
-   Do not make a commit or push if required tests fail, unless the user
    explicitly authorizes a documented exception. Never conceal failing
    checks.
-   If the environment lacks a required SDK, dependency, credential,
    remote, or platform tool, state that clearly and run all available
    relevant checks. Do not pretend an unavailable build was successful.
-   Before pushing, verify the intended branch, working tree, staged
    diff, build, and required tests.
-   After pushing, verify the remote update and report the commit hash
    and branch when available.

## 5. Required Change Workflow

For each task:

1.  Read `currentstate.md`, relevant parts of `plan.md`, and these
    instructions.
2.  Inspect repository status, branch, file layout, and relevant
    implementation before changing code.
3.  Identify acceptance criteria and likely failure/security cases.
4.  Make a small, coherent change.
5.  Add or update tests.
6.  Run formatting, static analysis, tests, and build checks relevant to
    the changed components.
7.  Review the complete diff for correctness, secrets, unrelated
    changes, generated files, and accidental deletions.
8.  Update `changelog.md` and `currentstate.md` when feasible.
9.  Commit and push according to the mandatory build and push
    discipline.
10. Report what changed, checks run and their actual outcomes,
    commit/push status, known limitations, and the next step.

Do not skip steps merely because the change appears small. Adapt checks
to the affected component and state any unavailable checks.

## 6. Architecture Boundaries

### Flutter mobile app

-   The Flutter app is the whole system: UI, market data, strategy, risk
    engine, order manager and Groww adapter, all in Dart (see plan.md
    section 4). There is no backend.
-   Android is the first target; preserve iOS compatibility.
-   Never embed Groww or AI credentials in source, assets or build
    artifacts. Users supply them at runtime and they live only in
    platform secure storage.
-   Groww trading endpoints are called only from the single Groww adapter
    module, and only after the order manager and risk engine approve.
-   Use TLS for all network traffic.
-   Validate all inputs in the domain layer; UI validation is never the
    only check.
-   Make paper/live mode, connection status, stale data, pending order
    status, and risk state visible.
-   Handle app suspension, process death, network changes, reconnects,
    and resynchronization.
-   Use platform-secure storage for necessary mobile tokens through
    vetted integrations.
-   Avoid excessive widget rebuilds and profile before applying
    low-level optimizations.
-   Never assume continuous background execution. Autonomous strategies
    must stop increasing risk when the app is suspended, killed or
    offline, and must reconcile with the broker before restarting.

### Order manager and Groww adapter (in-app)

-   Centralize Groww access in a dedicated adapter.
-   Use explicit timeouts, bounded retries, request correlation IDs, and
    redacted logs.
-   Respect the current documented broker rate limits.
-   Do not blindly retry order placement after an ambiguous timeout.
-   Do not assume an idempotency key, client-order-ID guarantee, or
    exactly-once behavior unless official documentation confirms it.
-   Treat broker acknowledgements, order status, trade fills, and
    positions as different facts.
-   Persist order intent and state transitions reliably.
-   Reconcile with broker state after reconnects, restarts, ambiguous
    results, and before resuming live trading.
-   Do not mark an order as filled without confirmed evidence.
-   Handle partial fills, rejected orders, cancellation races, delayed
    events, duplicate events, out-of-order events, and unknown outcomes.

### AI and strategy services

-   AI may generate research, strategy proposals, structured signals,
    and explanations.
-   AI must not have direct access to unrestricted broker credentials or
    a direct path that bypasses the order manager and risk engine.
-   Every proposal must be schema-validated, authorized, current, in
    scope, and unexpired.
-   Treat retrieved text, news, documents, and external content as
    untrusted. Prompt injection must not grant authority.
-   Model confidence cannot override risk controls.
-   Version prompts, models, strategy code, configuration, and research
    results where applicable.
-   Do not silently alter a live strategy or risk policy. Changes
    require controlled validation and authorization.
-   Paper trading is the default for new strategies.
-   Do not present backtest or simulated results as actual performance
    or as a guarantee of future returns.

## 7. Security Requirements

-   Never hard-code secrets or commit them to the repository.
-   Never log access tokens, API keys, passwords, private keys, signing
    credentials, or full secret-bearing requests.
-   Store secrets only in Android Keystore / iOS Keychain; inject CI
    secrets via the CI secret store, never into build artifacts.
-   Separate development, test, paper, and live
    credentials/configuration.
-   Use least privilege for application users, services, database roles,
    deployment identities, and CI.
-   Validate authorization, input schemas and limits in the domain layer
    before any order leaves the app.
-   Protect sessions and tokens; support revocation and secure recovery.
-   Require TLS for network traffic.
-   Validate WebSocket origin/identity and authorize each subscription.
-   Apply rate limits and abuse protections to authentication, order
    intents, AI requests, and administrative operations.
-   Encrypt sensitive data in transit and at rest.
-   Redact personal and financial information from logs, traces, crash
    reports, analytics, and support bundles.
-   Scan dependencies and container images; pin versions where practical
    and review upgrade risk.
-   Use secure defaults and avoid exposing internal services to the
    public internet.
-   Keep administrative and emergency actions auditable.
-   Review database migrations for data loss, locking, and rollback
    implications.
-   Create a threat model before enabling live trading and revisit it
    after major architecture changes.
-   Do not use production data or credentials in automated tests.

## 8. Trading Risk and Safety Rules

-   All manual and AI order intents must pass the in-app validation and
    risk engine.
-   The risk engine must be deterministic for hard limits and
    independent of AI reasoning.
-   Risk limits must not be editable or bypassable by the strategy they
    constrain.
-   Enforce approved instrument, strategy, order-type, session,
    quantity, notional, capital, exposure, and loss limits.
-   Reject orders when essential market data is stale or invalid.
-   Reject or suspend trading when authorization, broker state, or
    required risk state is unavailable.
-   Use a global kill switch and strategy-level stop controls.
-   Treat stopping new orders, cancelling working orders, and closing
    positions as separate actions.
-   Cancellation may fail; report unresolved orders and exposure
    clearly.
-   Do not automatically liquidate positions unless an explicit,
    separately reviewed policy authorizes it.
-   Do not enable autonomous live trading by default.
-   Do not submit real orders in CI, unit tests, integration tests,
    demos, or automated release checks.
-   Require explicit user authorization and documented
    operational/compliance acceptance before enabling live AI trading.
-   Confirm current Indian regulatory requirements and Groww's current
    policies before launch. Do not provide or encode assumptions as
    legal advice.

## 9. Performance and Reliability

-   Measure p50, p95, and p99 for relevant stages; do not report only
    averages.
-   Distinguish market-data delay, internal decision delay, risk-check
    delay, broker acknowledgement, and actual fill latency.
-   Never claim a broker acknowledgement means a trade is filled.
-   Use bounded queues and explicit backpressure behavior.
-   Detect data gaps, stale data, reconnects, excessive lag, queue
    saturation, and clock/timestamp anomalies.
-   Keep heavy LLM inference and historical analysis out of the
    time-sensitive execution path.
-   Use caches only where appropriate; the cache must not be the sole
    source of truth for critical order state.
-   Use health checks, metrics, structured logs, traces, and actionable
    alerts.
-   Make readiness checks include required dependencies and
    authorization state.
-   Define restart and reconnect recovery behavior.
-   After a crash or disconnect, reconcile broker orders, trades, and
    positions before resuming affected strategies.
-   Fail safely when critical state is uncertain.
-   Test broker timeouts, rate limits, partial fills,
    duplicate/out-of-order events, stale data, database unavailability,
    process crashes, and network interruptions.
-   Do not claim an SLA or latency guarantee that the architecture and
    measurements do not support.

## 10. Data, Database and Audit

-   Store durable order intents and state transitions.
-   Use transactions and constraints where appropriate to prevent
    inconsistent local state.
-   Define unique identifiers and correlation IDs for proposals, order
    intents, broker orders, fills, and audit events.
-   Preserve enough history to explain why each order was permitted,
    rejected, submitted, modified, cancelled, or left unresolved.
-   Record the active strategy/model/configuration version and
    applicable risk decision.
-   Keep timestamps and their semantics/time source explicit.
-   Define retention, access, backup, encryption, and restoration
    procedures.
-   Test backup restoration, not just backup creation.
-   Do not store unnecessary personal or financial information.
-   Do not commit database files, exports, actual trade histories, or
    sensitive fixtures.

## 11. Coding Standards

### General

-   Use clear names, small functions, explicit contracts, and consistent
    formatting.
-   Prefer maintainable solutions over clever shortcuts.
-   Avoid broad refactors mixed into feature changes.
-   Handle errors explicitly; never swallow exceptions without a
    documented reason.
-   Avoid unbounded retries, loops, queues, or memory growth.
-   Do not introduce dependencies without a clear need and a
    maintenance/security review.
-   Update configuration examples and docs when interfaces or
    operational behavior change.
-   Do not leave placeholder implementations on paths that can place
    real orders.
-   Mark unfinished functionality clearly and keep it disabled from live
    execution.

### Flutter / Dart

-   Run `dart format` and `flutter analyze`.
-   Use the selected state-management pattern consistently.
-   Keep API, domain, and presentation logic separated.
-   Avoid storing secrets in source, plain preferences, or logs.
-   Test lifecycle and reconnect behavior.
-   Add widget/unit tests for critical order and risk-state UI.
-   Profile rendering before low-level optimization.
-   Keep Android-specific implementations behind well-defined interfaces
    so iOS remains viable.

### Dart concurrency and reliability

-   Use explicit timeouts and cancellation for network and database
    operations.
-   Keep retry policies bounded and operation-aware.
-   Use isolates for heavy computation; never block the UI isolate.
-   Ensure streams, timers and subscriptions have clear lifetimes and
    are disposed.
-   Return actionable errors without leaking secrets.

### AI / research (Dart)

-   Use pinned, reviewed dependencies.
-   Use strongly typed schemas for all interfaces.
-   Validate external/model output before use.
-   Make backtests reproducible with recorded data ranges, parameters,
    versions, and assumptions.
-   Test leakage and look-ahead risks.
-   Keep secrets out of notebooks, artifacts, prompts, logs, and
    serialized model files.
-   Separate offline research from live runtime code.
-   Do not make a model or strategy change live without a controlled
    promotion process.

## 12. Testing Requirements

-   Add tests for new behavior and regression tests for fixed bugs.
-   Test positive, negative, boundary, and failure cases.
-   Test authorization and risk rejection paths, not only successful
    orders.
-   Use mocks/fixtures for broker behavior and keep fixtures free of
    secrets and real customer data.
-   Test ambiguous order submission and reconciliation.
-   Test partial fills, cancellation races, stale market data, and
    duplicate/out-of-order events.
-   Test app restart and process death with pending orders.
-   Test that AI proposals cannot exceed their authorization scope.
-   Test emergency stop and strategy suspension.
-   Test paper/live environment separation.
-   Run the relevant formatters, linters, unit/integration tests,
    security scans, and builds before commit/push.
-   Do not hide or silently skip failing tests.
-   Never run real-money order tests.

## 13. Release Management

-   Keep versioning and release notes consistent.
-   A release must identify its source commit, version, build result,
    tests, known issues, and rollback path.
-   For Android, produce the appropriate signed APK/AAB for the chosen
    distribution channel. Do not commit signing keys or passwords.
-   If publishing APKs to the repository's Releases section is an agreed
    distribution practice, attach only verified, intentional release
    artifacts, with checksums and release notes where appropriate. Keep
    AAB/APK selection aligned with the distribution channel.
-   Use GitHub Releases only if that is the configured repository
    workflow; do not invent a remote or publish destination.
-   iOS releases must use the approved Apple signing and distribution
    process.
-   Build artifacts must not be committed into source directories unless
    explicitly required by the established release workflow.
-   Do not release if required builds or tests fail.
-   Local database migrations must be versioned and tested so app
    updates cannot lose order or audit data, with a rollback plan.
-   Shipping an app build must not automatically enable live trading.
-   Live trading activation requires a separate explicit approval and
    verification checklist.

## 14. Changelog and Current State Updates

For every meaningful implementation task:

### `changelog.md`

Record: - Date. - Change summary. - Main files/components affected. -
Tests/builds run and actual outcomes. - Known limitations or migration
notes. - Commit/release identifier when available.

### `currentstate.md`

Record: - Project purpose and architecture as implemented. - Current
branch and latest verified commit when known. - Features implemented and
not implemented. - Build/test status, including commands and results. -
Current configuration/environment assumptions without secrets. - Known
bugs, risks, and blockers. - Current phase and the single best next
step.

Never describe planned features as implemented. Never record unverified
success.

## 15. Completion and Reporting

Before declaring a task complete, verify:

-   The change meets the stated acceptance criteria.
-   Relevant tests, static checks, and builds were actually run.
-   Security, authorization, risk, and error cases were considered.
-   No secrets or unrelated user changes were included.
-   `git diff` and `git diff --cached` were reviewed.
-   Documentation is updated.
-   The commit and push state is accurately reported.

The final task report must state: 1. What changed. 2. Files changed. 3.
Tests/builds run and actual outcomes. 4. Any checks that could not be
run and why. 5. Commit and push status. 6. Known limitations and next
step.

Do not claim completion, build success, release publication, deployment,
or push success without evidence.

## 16. Definition of Done

A change is done only when implementation, tests, error handling,
security implications, observable behavior, and relevant documentation
are integrated. MoneyHawk is not ready for live autonomous trading until
broker capabilities, current regulatory requirements, risk enforcement,
reconciliation, recovery, alerting, paper-trading validation, and
explicit authorization have all been reviewed and accepted.
