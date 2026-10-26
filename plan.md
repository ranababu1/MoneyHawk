# MoneyHawk: Project Plan

> **Document status:** Baseline plan\
> **Product:** MoneyHawk\
> **Primary platform:** Android first, followed by iOS\
> **Mobile framework:** Flutter (single app; no separate backend)\
> **Broker integration:** Groww Trade API\
> **Architecture decision (2026-10-27, user-approved):** All logic lives
> inside the Flutter app in Dart. There is no Go/Python backend.\
> **Primary objective:** Build a responsive, secure, reliable trading
> platform with manual and AI-assisted/autonomous trading modes.

## 1. Product Vision

MoneyHawk is a mobile-first trading platform that combines a fast manual
trading experience with an AI-driven strategy and execution system. It
should support clear operator control, strict risk enforcement,
auditable decisions, and reliable recovery when networks, services, or
the broker fail.

The platform is intended initially for personal use. It must not be
represented as exchange-colocated high-frequency trading infrastructure.
End-to-end latency depends on market-data availability, network
conditions, Groww API behavior, broker-side processing, order type,
liquidity, and exchange execution.

### Product principles

1.  **Execution correctness before raw speed.** Fast execution is
    valuable only when orders, positions, and risk state remain correct.
2.  **AI cannot bypass controls.** AI proposes or selects actions within
    explicit authorization; deterministic risk checks gate every order.
3.  **On-device execution with honest limits.** Strategies and order
    lifecycle management run inside the app (Dart). Phones can suspend or
    kill apps, so autonomous strategies run only while the app is active
    (Android foreground service where permitted) and must stop increasing
    risk, and alert the user, whenever the app is suspended, offline, or
    cannot verify state.
4.  **Broker is authoritative for actual orders and positions.**
    Internal state must be reconciled with Groww after uncertain events
    and before resuming after recovery.
5.  **Paper trading first.** Autonomous live trading remains disabled
    until all safety, reliability, and compliance gates are met.
6.  **Android first, shared Flutter codebase.** Design for iOS
    compatibility from the start, but prioritize Android implementation
    and release.
7.  **Observable and auditable by design.** Decisions, risk checks,
    orders, fills, failures, and operator actions must be traceable.

## 2. Goals and Non-Goals

### Goals

-   Provide a polished Flutter mobile app for Android first and iOS
    later.
-   Integrate with Groww's officially documented trading APIs.
-   Support manual order workflows and portfolio visibility.
-   Provide AI advisory, approval-based, and autonomous modes as
    explicitly configured capabilities.
-   Ingest available historical and real-time market data.
-   Support strategy research, backtesting, paper trading, and
    controlled live deployment.
-   Enforce independent risk limits and emergency controls.
-   Provide durable order-state handling, reconciliation, audit logging,
    alerts, and recovery.
-   Measure market-data, decision, broker-acknowledgement, and
    end-to-end execution latency.
-   Build repeatable tests, CI, secure releases, and operational
    documentation.

### Non-goals for the initial release

-   Guaranteed execution latency or guaranteed profitability.
-   Exchange colocation or claims of institutional HFT performance.
-   Unrestricted AI access to broker credentials or direct unvalidated
    order submission.
-   Unattended live trading before paper-trading and operational
    acceptance gates.
-   Supporting every asset class or strategy on day one.
-   Premature microservice proliferation or complex infrastructure
    without measured need.
-   Treating backtest results as proof of future performance.

## 3. Users and Operating Modes

### 3.1 Manual Mode

The user makes the trading decision. MoneyHawk provides:

-   Watchlists and supported live market data.
-   Instrument search and details.
-   Order entry, review, submission, modification, and cancellation
    where supported.
-   Order book, trade book, positions, holdings, and P&L where available
    through the broker API.
-   Clear pending, partially filled, filled, rejected, cancelled, and
    unknown status handling.
-   AI analysis as optional decision support without autonomous
    execution.
-   Configurable confirmations for high-impact actions.
-   Emergency controls to stop new orders and request cancellation of
    eligible open orders.

### 3.2 AI Approval Mode

AI proposes a structured trade. The user reviews the instrument, side,
quantity, order type, price parameters, rationale, risks, and expiry
before approving it. Approval must expire and must not be reusable for a
different or modified order.

### 3.3 AI Autonomous Mode

The user explicitly enables a specific approved strategy and defines its
permissions, instrument scope, trading hours, capital allocation,
per-trade risk, daily loss threshold, position/exposure limits, and stop
conditions. AI strategies may only operate within this authorization.

The system must support disabling a strategy and switching modes without
allowing manual and autonomous strategies to unintentionally compete for
the same exposure. Mode changes must be serialized and audited.

### 3.4 Paper Trading Mode

Paper trading is the default for new strategies. Simulated fills must be
labelled as simulated and must account for reasonable costs and slippage
assumptions. Paper results must never be presented as actual broker
fills.

## 4. High-Level Architecture

Single Flutter app with clearly separated Dart layers (presentation,
domain, data). Layers communicate through explicit interfaces so that
Android-specific code stays isolated and iOS remains viable.

``` text
Flutter app (Android first, iOS next)
  Presentation (screens, Riverpod state)
        |
  Market-data module     Strategy & AI module
        |                      |
        |                Trade proposals
        |                      v
        |            Deterministic risk engine
        |                      |
        +--------------> Order manager
                               |
                        Groww API adapter
                               |
                          Groww broker

Local encrypted database (e.g. SQLite): configuration, order intents,
audit, strategy versions, risk events, reconciliation snapshots.
Secure storage (Android Keystore / iOS Keychain): broker and AI
credentials. Local structured logs and metrics for latency and incidents.
```

### Architectural boundaries

-   The app is the trading engine. Groww access goes only through the
    single Groww adapter module.
-   Broker and AI credentials are stored only in platform secure storage
    and must never appear in source, logs, analytics, crash reports, or
    AI prompts. They are supplied by the user at runtime.
-   AI and strategy modules cannot submit orders directly. They create
    structured proposals for validation by the order manager and risk
    engine.
-   The risk engine must be independent of the model's reasoning and
    confidence score, and strategies cannot edit its hard limits.
-   The order manager owns order lifecycle state and reconciles with
    Groww.
-   Autonomous strategies run only while the app is active. On
    suspension, process death, or connectivity loss they must stop
    increasing risk; working orders and positions are reconciled with the
    broker on resume before any strategy restarts.
-   If essential market data, broker state, risk state, or authorization
    becomes unreliable, affected strategies must stop increasing risk.
-   Because there is no server, there is no off-device kill switch:
    open orders and positions remain at the broker if the app dies. The
    user must be told this clearly, and the app must offer guidance to
    manage exposure in the Groww app directly.

## 5. Proposed Technology Stack

  --------------------------------------------------------------------------
  Area                    Initial recommendation  Notes
  ----------------------- ----------------------- --------------------------
  Mobile                  Flutter / Dart          Android first; preserve
                                                  iOS compatibility

  State management        Riverpod (or Bloc if    Choose one and apply
                          project conventions     consistently
                          favor it)               

  Order management /      Dart modules in the    Deterministic lifecycle,
  broker adapter          app (isolates where     explicit timeouts and
                          needed)                 state transitions

  AI / quantitative       Dart in the app; LLM    Backtesting in Dart;
  research                via provider API using  heavy analysis off the
                          user-supplied key       order path

  Broker transport        HTTPS + Groww streams   TLS, reconnect and
                          as documented           resynchronization

  Database                Encrypted local         Durable configuration,
                          SQLite (e.g. drift +    intents, orders, audit
                          SQLCipher), evaluated   and operational state
                          at implementation

  Secrets                 flutter_secure_storage  Android Keystore / iOS
                                                  Keychain

  Background execution    Android foreground      Not guaranteed; see
                          service; iOS limits     section 4 boundaries
                          apply

  Observability           Structured local logs,  Redacted; exportable
                          in-app metrics,         support bundle
                          notifications           

  CI                      Automated formatting,   No release without passing
                          linting, tests,         required checks
                          security scans, build   
                          checks                  
  --------------------------------------------------------------------------

All versions and API details must be checked against official
documentation at implementation time. Do not assume that a specific
Groww endpoint, stream, order type, market-data field, rate limit, or
authentication flow is available without verifying current official docs
and account entitlements.

## 6. Low-Latency Design

### Latency categories to measure separately

1.  Market event timestamp to validated data available to a strategy.
2.  Data availability to signal/proposal generation.
3.  Proposal receipt to risk decision.
4.  Risk approval to broker request start.
5.  Broker request start to acknowledgement.
6.  Order acknowledgement to fill, measured separately from application
    latency.
7.  End-to-end decision-to-fill time.

Record p50, p95, and p99 distributions, sample counts, error rates, and
measurement methodology. Keep clock-source and timestamp semantics
documented. Do not conflate broker acknowledgement with a completed
execution.

### Design practices

-   Prefer supported streaming feeds over frequent polling where
    appropriate.
-   Reuse network connections when supported and safe.
-   Keep LLM inference and heavy historical analysis out of the
    synchronous order path.
-   Use lightweight deterministic rules or trained models for
    time-sensitive signal evaluation.
-   Maintain an in-memory view of current validated market data and
    working state, backed by durable order records.
-   Avoid unnecessary synchronous database and cross-service calls in
    the critical path while ensuring durable intent and recovery
    requirements are met.
-   Batch or coalesce UI updates where appropriate without hiding
    material price/order state changes.
-   Detect stale, delayed, missing, out-of-order, or invalid market
    events.
-   Use bounded queues and explicit backpressure behavior.
-   Benchmark on realistic networks and during representative market
    load.
-   Optimize based on measurements rather than assumed millisecond
    targets.

### Latency SLOs

Do not promise hard numerical latency targets before measuring the Groww
API and hosting path. Establish baseline distributions in a
non-production environment, define internal budgets, and document which
portions are under MoneyHawk's control versus broker/network/exchange
control.

## 7. Groww Integration

Build a dedicated adapter around the officially documented Groww Trade
API.

Responsibilities:

-   Authentication and token lifecycle handling according to current
    official documentation.
-   Market data and historical data retrieval for supported endpoints.
-   Instrument metadata and symbol mapping.
-   Order placement, modification, cancellation, status retrieval, and
    trade/position reconciliation where supported.
-   Rate-limit handling and backoff that respects documented
    restrictions.
-   Request correlation IDs and redacted structured logs.
-   Explicit timeout, retry, and ambiguous-outcome handling.
-   Contract tests or recorded fixtures that do not contain real
    credentials or sensitive customer data.

### Critical submission rule

Never blindly retry an order submission after a timeout or connection
loss. The request may have reached the broker even if the
acknowledgement did not reach MoneyHawk. Mark the outcome as uncertain,
query/reconcile using supported broker records and client references
where available, and only take a subsequent action once duplicate risk
is controlled.

Do not assume that the broker provides idempotency keys or
client-order-ID semantics unless verified. If the API cannot guarantee
safe idempotency, document the residual risk and use conservative
reconciliation procedures.

## 8. AI and Quantitative Trading Design

### 8.1 Responsibilities

-   **Research AI:** investigates hypotheses and proposes strategies
    using historical evidence.
-   **Strategy runtime:** computes approved signals using bounded,
    versioned logic.
-   **Tactical model:** optionally ranks or scores opportunities using
    current validated features.
-   **LLM agent:** interprets high-level instructions, explains
    decisions, and proposes configuration changes. It is not an
    unrestricted order executor.
-   **Risk engine:** deterministically accepts or rejects every order
    intent.
-   **Order manager:** submits approved orders and tracks their
    lifecycle.

### 8.2 Structured trade proposals

Every proposal should have a validated schema, including:

-   Strategy ID and immutable strategy version.
-   Instrument identifier from an approved universe.
-   Side, quantity, order type, and price parameters.
-   Timestamp and market-data freshness reference.
-   Entry conditions, exit conditions, and expiry.
-   Risk budget and expected exposure.
-   Rationale and model version.
-   Approval requirement and authorization scope.
-   Correlation ID and unique proposal ID.

Reject malformed, expired, out-of-scope, stale-data, or unauthorized
proposals. Confidence scores must not bypass controls.

### 8.3 Research and validation

-   Build reproducible backtests with explicit assumptions.
-   Include brokerage, applicable taxes/fees, spread, slippage,
    liquidity and realistic fill assumptions.
-   Prevent look-ahead bias and data leakage.
-   Use chronological train/validation/test splits and walk-forward
    evaluation where appropriate.
-   Evaluate drawdown, volatility, turnover, concentration, tail loss,
    risk-adjusted return and regime sensitivity, not only win rate.
-   Compare against simple baselines.
-   Version data, code, parameters, model artifacts and results.
-   Require paper trading before any live authorization.
-   Detect model drift and stop or downgrade a strategy when its
    assumptions or data quality fail.
-   Do not allow live self-modification of strategies without a
    controlled release/approval process.

### 8.4 AI prompt and tool security

Treat all external text, news, documents, instrument descriptions, and
retrieved content as untrusted data. Prompt injection must not grant
permissions or change risk limits. The AI tool layer must expose only
narrowly scoped capabilities and must not expose broker secrets.

## 9. Risk Management

The risk engine is a mandatory gate for manual and AI-generated orders,
with policy differences explicitly configured by mode.

Minimum controls:

-   Maximum quantity and order notional.
-   Per-trade risk budget.
-   Maximum daily loss and drawdown action.
-   Maximum open positions and aggregate exposure.
-   Instrument, product, order-type and strategy allowlists.
-   Capital/margin validation using reliable broker state.
-   Price collars and sanity checks where supported and appropriate.
-   Trading-session and market-status validation.
-   Stale-data rejection.
-   Duplicate intent detection.
-   Rate-limit and order-frequency controls.
-   Strategy-specific limits and global portfolio limits.
-   Cooldown or lockout after repeated failures.
-   Explicit authorization for live AI mode.
-   Emergency stop that blocks new risk-increasing orders.

Risk limits must be enforced in the app's risk engine, in code the UI and
strategies cannot bypass, and must fail closed when
required state is unavailable. A strategy must not be able to edit or
bypass its own hard limits.

### Emergency behavior

Stopping new orders, cancelling open orders, and closing existing
positions are separate actions. Cancellation can fail or be delayed;
filled orders cannot be cancelled. The emergency workflow must display
actual broker state, record each action, retry only safely, and alert
the operator about unresolved exposure. Do not automatically liquidate
positions unless a separate, explicit policy authorizes it.

## 10. Security and Privacy

-   Keep broker and AI credentials out of source control, app assets,
    prompts, logs, analytics and crash reports. Users enter them at
    runtime; they are stored only in Android Keystore / iOS Keychain via
    vetted Flutter integrations.
-   Encrypt the local database at rest; use TLS for all network traffic
    and consider certificate pinning for broker endpoints.
-   Gate app access with device authentication (biometric/PIN) and
    require re-authentication for live-mode actions.
-   Revoke or rotate broker tokens when a device is lost; document the
    procedure.
-   Validate all inputs, schemas and limits in the domain layer before
    any order leaves the app.
-   Apply local rate limits and order-frequency controls that respect
    Groww's documented limits.
-   Redact secrets, personal data and sensitive trading details from
    operational logs.
-   Protect audit records from unauthorized modification and define
    retention/access rules.
-   Pin and scan dependencies; generate and review software bills of
    materials where practical.
-   Use signed builds and controlled release credentials.
-   Separate development, test, paper-trading, and live environments.
-   Never use real account credentials in automated tests or commit
    fixtures.
-   Define backup encryption, access control, retention and restore
    testing.
-   Complete a threat model before enabling live trading.

## 11. Reliability, Recovery and Observability

### Order lifecycle

Implement explicit order state transitions, including at least created,
validated, submitted, open, partially filled, filled, cancel requested,
cancelled, rejected, expired, and outcome unknown as applicable to the
broker's actual lifecycle. Enforce legal transitions and preserve the
event history.

### Recovery

On restart, reconnect, or uncertainty:

1.  Disable new risk-increasing orders for affected strategies.
2.  Load durable intents and order-event history.
3.  Reconnect using the documented authentication process.
4.  Query broker orders, trades, positions, and other relevant state.
5.  Reconcile internal state with broker state.
6.  Resolve or explicitly flag unknown orders and discrepancies.
7.  Recalculate exposure and risk.
8.  Resume only after required checks pass or the operator authorizes a
    documented recovery action.

### Observability

Track:

-   Service health and dependency health.
-   Market-data age, gaps, and reconnects.
-   Strategy processing delay and queue depth.
-   Risk rejection counts and reasons.
-   Broker API latency, rate limits, errors and timeouts.
-   Order acknowledgements, partial fills, rejects and reconciliation
    differences.
-   Decision-to-submit and submit-to-ack latency distributions.
-   Current mode, strategy state, risk utilization and kill-switch
    state.
-   CPU, memory, database latency, storage and backup status.

Alerts must be actionable and tested. Logs and metrics must not be the
only record of critical order state.

## 12. Mobile UX and App Security

Primary screens:

1.  App lock and broker connection/session management.
2.  Market overview and watchlists.
3.  Instrument detail and supported charts.
4.  Manual order ticket.
5.  Orders and trade book.
6.  Positions, holdings and P&L.
7.  AI strategy list and status.
8.  Strategy instructions, limits and authorization.
9.  AI proposal review and approval.
10. Paper/live mode indicators.
11. Risk dashboard and emergency controls.
12. Notifications, connection health and audit history.
13. Settings and security controls.

UX requirements:

-   Always make paper versus live mode unmistakable.
-   Show connection and market-data freshness.
-   Show the final order parameters before approval when confirmation is
    required.
-   Prevent accidental repeated taps from creating duplicate requests.
-   Display pending/unknown states honestly rather than implying
    success.
-   Support reconnect and state resynchronization.
-   Make emergency stop accessible without hiding it behind AI screens.
-   Do not depend on push notifications as the sole emergency alert
    channel.
-   Respect mobile lifecycle behavior; no assumption that background
    execution is continuous.

## 13. Development Phases and Exit Criteria

### Phase 0: Discovery and compliance validation

-   Review current official Groww documentation and account
    entitlements.
-   Confirm supported instruments, data streams, historical granularity,
    order operations, authentication, limits, and sandbox/paper options.
-   Validate current Indian regulatory and broker requirements for
    intended retail algorithmic use.
-   Document initial instruments and strategy horizons.
-   Produce architecture decisions and threat model.

**Exit:** No unverified API assumption is treated as a guaranteed
capability; compliance questions have documented owners and resolutions.

### Phase 1: Foundation

-   Repository structure, branch and CI setup.
-   Flutter app shell and layered Dart module skeleton.
-   Configuration and secret handling.
-   Device authentication and secure-storage baseline.
-   Structured logging, health checks, test framework.
-   Create `changelog.md` and `currentstate.md`.

**Exit:** Builds and automated checks pass; secrets are not embedded in
source or client artifacts.

### Phase 2: Broker and manual trading foundation

-   Groww adapter and market-data handling.
-   Instrument/watchlist views.
-   Manual order workflows.
-   Order state machine and event persistence.
-   Broker state reconciliation.
-   Rate limits, timeouts, ambiguous outcomes and duplicate protection.

**Exit:** Integration and failure tests demonstrate correct behavior for
normal and uncertain order outcomes in the permitted test environment.

### Phase 3: Risk and operations

-   Independent risk engine.
-   Exposure and loss limits.
-   Emergency stop and cancellation workflow.
-   Metrics, alerting, audit and restart recovery.
-   Failure-injection tests.

**Exit:** Risk controls cannot be bypassed by the UI or AI;
restart/disconnect tests do not silently lose order state.

### Phase 4: Historical research and backtesting

-   Historical data ingestion and validation.
-   Feature/indicator pipeline.
-   Reproducible backtest runner.
-   Cost/slippage assumptions and out-of-sample testing.
-   Strategy/model versioning.

**Exit:** Results are reproducible and include realistic costs, drawdown
and known limitations.

### Phase 5: AI proposals and paper trading

-   Structured AI proposal schema.
-   Strategy runtime and inference integration.
-   Approval workflow.
-   Paper broker/simulator and reconciliation reports.
-   Drift and health controls.

**Exit:** Strategies operate in paper mode within limits, with complete
audit records and tested shutdown/recovery.

### Phase 6: Android release

-   Device and OS compatibility testing.
-   Secure storage, lifecycle and reconnect testing.
-   Signed release build and release notes.
-   Installable artifact and checksums where applicable.
-   Controlled internal testing before broader distribution.

**Exit:** Release checks pass and the documented rollback/recovery
process is ready.

### Phase 7: Controlled live authorization

-   Confirm broker and regulatory requirements.
-   Explicit user authorization for selected strategy and scope.
-   Conservative initial exposure limits.
-   Active monitoring and emergency procedure rehearsal.
-   Defined criteria for disabling a strategy.

**Exit:** All go-live gates are approved. Live trading is never enabled
by default.

### Phase 8: iOS release and measured scaling

-   Complete iOS secure storage, lifecycle and notification
    integrations.
-   Test on physical devices.
-   Review platform-specific App Store and broker requirements.
-   Scale storage, data processing or service topology only based on
    measured demand.

**Exit:** Platform-specific security and reliability checks pass.

## 14. Testing Strategy

Required layers:

-   Unit tests for calculations, risk rules, validation, state
    transitions and strategy logic.
-   Contract tests for Groww adapter request/response handling based on
    current official API contracts.
-   Integration tests for database, authentication, event persistence
    and reconciliation.
-   Flutter widget and application tests.
-   End-to-end tests for manual and AI approval workflows.
-   Load tests for streaming updates, concurrent users/strategies and
    bounded queues.
-   Failure tests for timeout, disconnect, process restart, rate limit,
    stale data, partial fill and broker unavailability.
-   Security tests for authorization bypass, secret leakage, replay,
    injection and malformed payloads.
-   Backtest validation for leakage, costs and reproducibility.
-   Release smoke tests on physical Android devices; later iOS devices.

Automated tests must use mock or explicitly approved test environments.
Never submit real trades in CI.

## 15. Release and Deployment Strategy

-   Use separate development, test, paper-trading and live
    configurations.
-   Keep live credentials and signing keys out of repository history.
-   Build immutable, versioned artifacts.
-   Run formatting, lint, unit/integration tests, dependency scans and
    build checks before release.
-   Generate release notes and record commit/version identifiers.
-   For Android, maintain a controlled signed release process and
    publish APK/AAB artifacts as appropriate to the chosen distribution
    channel.
-   If the project adopts GitHub Releases, publish only verified
    artifacts and attach release notes and checksums. Do not assume both
    APK and AAB are suitable for every distribution channel.
-   For iOS, use the approved Apple signing and distribution workflow.
-   Keep local database migrations versioned, tested and reversible or
    backed up so app updates never strand order or audit data.
-   Live-trading enablement is a separate, explicit operational approval
    from shipping an app build.

## 16. Initial Acceptance Criteria

-   Android app builds reproducibly from documented instructions.
-   iOS compatibility is not blocked by Android-specific architectural
    assumptions.
-   Manual and AI modes are visibly distinct and properly authorized.
-   AI cannot bypass risk controls or access broker credentials.
-   All order intents and broker events are durably traceable.
-   Ambiguous submission outcomes trigger reconciliation, not blind
    retries.
-   Reconnect/restart recovery reconciles with broker state before
    resuming.
-   Stale market data and essential service failures suspend affected
    strategies safely.
-   Risk limits and emergency stop are covered by automated tests.
-   Paper trading is the default for new strategies.
-   Latency metrics separate internal processing, broker
    acknowledgement, and actual fills.
-   Release and rollback procedures are documented.
-   Current broker and regulatory requirements are validated before live
    automation.

## 17. Open Decisions

These must be decided during Phase 0 and recorded in architecture
decision records:

-   Initial instruments: equities, intraday, derivatives, or a smaller
    subset.
-   Initial trading horizon and strategy family.
-   Personal account scale and concurrency requirements.
-   Exact loss/exposure limits and whether manual and AI modes share
    aggregate limits.
-   Whether Groww terms permit on-device algorithmic use and what static
    IP or other requirements apply to a mobile network.
-   Local app lock and broker-credential recovery process.
-   Data retention and storage sizing.
-   Whether external news/data vendors are needed and their licensing
    constraints.
-   Which Groww API capabilities are available under the user's account.
-   Current compliance and broker approval requirements for autonomous
    strategies.

## 18. Definition of Done

A feature is complete only when its implementation, tests, security
implications, error handling, logs/metrics, user-facing states, and
documentation are integrated. Update `changelog.md` and
`currentstate.md` as part of the change when feasible. Never enable live
trading merely because a feature compiles or a happy-path test passes.
