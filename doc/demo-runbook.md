# Demo Runbook

## Start

```sh
bin/rails server -p 3001
```

Open `http://127.0.0.1:3001`.

## Canonical OKF Checks

Ask:

- `Can I get a refund after renewing Flowbase yesterday?`
- `How much does Growth cost if we need 14 seats?`
- `How long are automation run logs retained on Enterprise?`

Expected result:

- Badge: `OKF - Curated`
- Sources list shows OKF concept titles and `flowbase://...` resources.
- Context drawer includes markdown policy bodies.

## RAG Checks

Ask:

- `A customer's Slack approval step keeps timing out after OAuth reconnect. What worked before?`
- `Have customers reported CSV exports losing timezone information?`
- `A Jira workspace import caused duplicate webhook delivery. What prior fix is closest?`

Expected result:

- Badge: `RAG - Retrieved`
- Sources list shows `KnowledgeChunk` ticket/source rows.
- Context drawer includes retrieved support-history chunks.

## Large Data Check

Seed a larger corpus:

```sh
bin/rails 'rag:seed_large[300]'
bin/rails runner 'puts KnowledgeChunk.count'
```

Then ask a generated-history query:

```text
A Teams private-channel notification failed after a workspace import. What prior resolution is closest?
```

The answer should use retrieved support history and cite generated `LOAD-...`
sources if those chunks are nearest.
