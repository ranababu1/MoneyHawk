# Phase 0 Findings: Groww Trade API (checked 2026-10-27)

Sources: groww.in/trade-api/docs (landing), /docs/curl, /docs/python-sdk,
groww.in/blog/static-ip-api-trading-setup. Re-verify before coding against
any item. Items marked UNVERIFIED were not found in official pages.

## Verified from official docs
- Base URL (inferred from examples): `https://api.groww.in/v1`. Headers:
  `Authorization: Bearer <token>`, `Accept: application/json`,
  `X-API-VERSION: 1.0`.
- Auth: (1) access token generated in Groww settings, expires daily 6:00 AM;
  (2) API key + secret via `POST /v1/token/api/access` with SHA-256 checksum
  of secret+epoch timestamp (valid 10 min), needs daily approval;
  (3) TOTP flow, also daily approval. Token endpoint: 150 requests/24h.
- Rate limits (per type, shared across APIs in the type):
  Auth 5/s 30/min; Orders (create/modify/cancel) 10/s 250/min;
  Live Data (quote/LTP/OHLC) 10/s 300/min; Non-Trading (order status/list,
  trades, positions, holdings, margin) 20/s 500/min.
- Segments: CASH and FNO. MCX not available. Exchanges NSE/BSE.
- `order_reference_id`: optional, user-provided, 8-20 alphanumeric chars;
  duplicate returns error GA007. Whether it gives exactly-once semantics is
  UNVERIFIED, so reconcile after timeouts regardless.
- Live feed: WebSocket streaming of market feeds and order updates;
  up to 1000 subscriptions. Exact subscription types UNVERIFIED (Feed page
  not read).
- Official SDKs: Python and cURL docs only. No Dart/Flutter SDK, so the
  adapter must be written against the REST/stream contract.
- Response envelope: `status` SUCCESS/FAILURE, `payload`, `error{code,
  message,metadata}`. Errors GA000-GA007.

## BLOCKER for the app-only architecture
- Groww states order placement must originate from a registered static IP
  (primary + optional secondary; orders from other IPs may be rejected).
  This follows SEBI's retail algo framework (NSE circular NSE/INVG/67858
  referenced by third parties; not read directly).
- A phone on mobile data or home Wi-Fi normally has a dynamic IP, so
  on-device order placement is likely to fail or be rejected. Groww's page
  is silent on mobile IPs and on whether data-only calls need a static IP.
- Options to decide: (a) tiny always-on relay/proxy with a static IP that
  only forwards signed order calls (reintroduces a server, contradicting
  the current app-only decision); (b) a static-IP VPN/VPS egress used by the
  app; (c) manual-order-only via Groww's own app plus read-only/paper in
  our app; (d) confirm with Groww support whether their cloud or another
  route lifts the requirement.

## Still open
- Historical data intervals/limits, Smart Orders, full order-type/product/
  validity lists, feed message formats, API pricing (third parties say
  Rs 499/month; unconfirmed), regulatory status of retail autonomous algos,
  Groww terms on personal algo use.
