# Setup And Operations

## Local Setup

```sh
cp .env.example .env
bundle install
bin/rails db:prepare
bin/rails rag:seed
bin/rails server -p 3001
```

Required environment variables:

- `ANTHROPIC_API_KEY`
- `OPENAI_API_KEY`

Optional environment variables:

- `ANTHROPIC_MODEL`, default `claude-sonnet-4-6`
- `OPENAI_EMBEDDING_MODEL`, default `text-embedding-3-small`

## Database Requirements

PostgreSQL must have the `vector` extension available. On macOS:

```sh
brew install pgvector
bin/rails db:prepare
```

## Seed Data

Base demo data:

```sh
bin/rails rag:seed
```

Larger test corpus:

```sh
bin/rails 'rag:seed_large[300]'
```

The large seed task generates synthetic support-history notes and embeds them in
batches. Increase or decrease the count based on how much API usage you want.
The task is idempotent by `source`, so rerunning the same count skips existing
records.

For adding your own OKF markdown files or RAG source files, see
`doc/extending-knowledge.md`.

## Verification

```sh
bin/rails routes
bin/rails zeitwerk:check
bundle exec rspec
curl -i http://127.0.0.1:3001/
```

For live answer checks, use the UI examples:

- Refund, plan, retention, and escalation questions should show `OKF - Curated`.
- Troubleshooting and support-history questions should show `RAG - Retrieved`.
