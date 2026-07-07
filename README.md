# OKF + RAG Rails Demo

This Rails 8.1 app demonstrates a hybrid support knowledge architecture for a
fictional SaaS company called Flowbase.

The curated OKF layer answers exact, high-stakes questions from markdown concept
files. The RAG layer embeds messy support-history snippets into PostgreSQL with
pgvector and retrieves the nearest chunks for exploratory questions. A thin
router chooses the source per query, and the UI shows which path answered.

## Stack

- Rails 8.1.3 with server-rendered ERB views and Propshaft assets
- PostgreSQL with the `vector` extension
- `neighbor` and `pgvector` for ActiveRecord vector search
- Anthropic Ruby SDK for Claude answer generation and ambiguous routing
- OpenAI `text-embedding-3-small` for embeddings because Anthropic does not
  provide a first-party embeddings API for this workflow
- RSpec for request, service, and model specs

## Setup

Install PostgreSQL and pgvector first. On macOS with Homebrew, that is usually:

```sh
brew install postgresql@16 pgvector
brew services start postgresql@16
```

Then configure and boot the app:

```sh
cp .env.example .env
bundle install
bin/rails db:create db:migrate
bin/rails rag:seed
bin/rails server
```

Add real values for `ANTHROPIC_API_KEY` and `OPENAI_API_KEY` in `.env` before
seeding or asking live questions.

## Try Both Paths

Canonical examples route to OKF:

- `Can I get a refund after renewing Flowbase yesterday?`
- `How much does Growth cost if we need 14 seats?`
- `How long are automation run logs retained on Enterprise?`

Exploratory examples route to RAG:

- `A customer's Slack approval step keeps timing out after OAuth reconnect. What worked before?`
- `Have customers reported CSV exports losing timezone information?`

The result page displays the question, route badge, answer, cited sources, and
the exact context sent to Claude.

## File Structure

- `knowledge/` contains the OKF markdown bundle.
- `doc/` contains architecture, setup, demo runbook, and knowledge extension documentation.
- `app/services/okf_concept.rb` parses OKF frontmatter and bodies from disk.
- `app/services/knowledge_router.rb` implements rules-first routing plus Claude fallback.
- `app/services/support_agent.rb` builds source-specific context and asks Claude for an answer.
- `app/models/knowledge_chunk.rb` stores support-history chunks and performs vector search.
- `db/seeds.rb` embeds the sample RAG dataset.

To add a new OKF concept, create a markdown file under `knowledge/` with YAML
frontmatter. `type` is required; `title`, `description`, `resource`, `tags`,
and `timestamp` are recommended. Link concepts with normal markdown links.

For detailed instructions on adding OKF files and RAG records/files, see
`doc/extending-knowledge.md`.

## Tests

```sh
bundle exec rspec
```

Specs stub external API calls. Database-backed tests require the test database
to exist and the migrations to be loaded.

## Larger Test Data

Generate a larger synthetic RAG corpus with batched embeddings:

```sh
bin/rails 'rag:seed_large[300]'
```

See `doc/demo-runbook.md` for queries that exercise the generated data.

## Production Notes

For a real production system, keep the OKF bundle in reviewed content workflows,
embed documents asynchronously, store query and route telemetry, add auth and
rate limits, monitor LLM and embedding failures, and evaluate routing decisions
against a labeled dataset. The demo is intentionally small, but the boundaries
are production-shaped: curated policy, retrieval, routing, and answer generation
are separate objects.
