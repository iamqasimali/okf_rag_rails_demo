# Implementation Prompt: OKF + RAG Hybrid Knowledge Demo (Rails)

Use this as a single prompt for Claude Code (or paste section by section if you want to review each stage before moving on). It's written to produce a runnable, demoable Rails 8 app with production-shaped boundaries, clear docs, focused tests, and enough UI polish to show the architecture credibly.

---

## The prompt

```
I want to build a small Rails 8 demo app called `okf-rag-demo` that shows a
hybrid AI knowledge architecture: a curated OKF (Open Knowledge Format) layer
for exact, high-stakes answers, and a RAG (Retrieval-Augmented Generation)
layer backed by pgvector for everything else. A thin router decides, per
query, which layer answers. Build the whole thing end to end.

## Context

- OKF is Google Cloud's markdown knowledge spec: a directory of markdown
  files, one per "concept," each with a YAML frontmatter block where `type`
  is the only required field (optional: title, description, resource, tags,
  timestamp). Concepts link to each other with normal markdown links.
- RAG here means: chunk documents, embed each chunk, store the vectors in
  Postgres via pgvector, and do nearest-neighbor search at query time.
- The router classifies each incoming question as "canonical" (routes to
  OKF, returns an exact cited answer) or "exploratory" (routes to RAG,
  returns the closest matching chunks).
- The demo domain is a fictional SaaS company's customer support agent.

## Tech stack

- Rails 8 (minimal server-rendered views, no need for a JS framework)
- PostgreSQL with the `pgvector` extension
- `neighbor` gem for ActiveRecord + pgvector integration
- Anthropic Ruby SDK for both the embedding-adjacent LLM calls (router
  classification) and the final answer generation (use `claude-sonnet-4-6`)
  — if there's no first-party Anthropic embeddings endpoint, use OpenAI's
  `text-embedding-3-small` for embeddings specifically, and note that
  clearly in a comment
- RSpec for tests
- No frontend framework — plain ERB views + polished minimal CSS. This is a
  demo, but it should feel production-ready enough to present.

## Step 1: Project scaffolding

- Generate a new Rails 8 app (server-rendered views, Postgres as the database)
- Add gems: `pg`, `pgvector`, `neighbor`, `anthropic` (or the correct current
  gem name for the Anthropic Ruby SDK — check first), `dotenv-rails` for
  local env vars, `rspec-rails`
- Set up `.env.example` with placeholders for `ANTHROPIC_API_KEY` and
  `OPENAI_API_KEY` (for embeddings), and load them via dotenv
- Enable the `vector` extension in a migration

## Step 2: The OKF bundle

Create a `/knowledge` directory at the app root (not inside `app/`) containing
a small hand-curated OKF bundle for a fictional company called "Flowbase."
Structure it like this:

    /knowledge
      index.md
      /policies
        index.md
        refund-window.md
        data-retention.md
      /pricing
        index.md
        plans.md
      /support
        index.md
        escalation-path.md

Each concept file needs real, specific, made-up-but-plausible content (not
placeholder lorem ipsum) — for example refund-window.md should state an
actual policy like "14 days from purchase, unused, original packaging" so
the demo has something concrete to answer with. Give each file a `type`,
`title`, `description`, `tags` (array), and `timestamp` in frontmatter, and
link related concepts to each other with markdown links in the body (e.g.
pricing/plans.md should link to policies/refund-window.md).

Write a plain Ruby class `OkfConcept` (not an ActiveRecord model — this
reads directly off the filesystem) that can:
- load and parse every concept file in the bundle (parse YAML frontmatter
  + markdown body)
- find concepts by tag
- find concepts by type
- return a lightweight "map" of the whole bundle (path, type, title, tags)
  for progressive disclosure — i.e. what the router sees before deciding
  to dig into a specific file

## Step 3: The RAG side

Create a `KnowledgeChunk` ActiveRecord model backed by pgvector via the
`neighbor` gem, with columns: `content` (text), `source` (string, e.g. a
fake ticket ID or transcript filename), `embedding` (vector, dimension
matching whichever embedding model we use), timestamps.

Add a `has_neighbors :embedding` association and a class method
`.search(query_embedding, k: 5)` using cosine distance.

Create a seed dataset: 15-20 fake, varied "support ticket" or "forum post"
style unstructured text snippets (things like troubleshooting reports, edge
case questions, one-off bugs) that would plausibly live in a RAG index
rather than a curated policy doc. Write a rake task or seed file that
embeds each one via the embedding API and inserts it as a KnowledgeChunk.

Write an `EmbeddingClient` service class that wraps whichever embedding API
we're using, takes a string, returns a vector.

## Step 4: The router

Build a `KnowledgeRouter` service class. Implement it in two stages so the
demo can show the difference:

1. A rules-based first pass: classify as "okf" if the query text or its
   likely tags overlap with what's in the OKF bundle's tag list (refund,
   pricing, plan, escalation, retention, etc.), otherwise "rag."
2. A fallback LLM classifier: if the rules-based pass is ambiguous, make one
   cheap call to Claude asking it to return strictly "okf" or "rag" given
   the query and a short list of available OKF concept titles/tags (this is
   the "map" from Step 2). Parse the response defensively.

`KnowledgeRouter.call(query)` should return a hash like:
  { source: :okf | :rag, concepts: [...] } or { source: :rag, chunks: [...] }

## Step 5: The agent

Build a `SupportAgent` service class with an `answer(query)` method that:
1. Calls `KnowledgeRouter.call(query)`
2. Builds a context string from whichever source came back — if OKF,
   include the concept's title, body, and resource link so the final
   answer can cite it; if RAG, include the top-k chunk contents and their
   sources
3. Sends a single message to Claude (`claude-sonnet-4-6`, max_tokens 1000)
   with a system-style instruction that it must answer using only the
   provided context, and must explicitly say whether the answer came from
   a "curated policy" (OKF) or "retrieved support history" (RAG) so the
   demo visibly shows which path fired
4. Returns the answer text plus metadata: which source was used, and (for
   OKF) the resource link; (for RAG) the source list

## Step 6: A minimal demo UI

One controller, `QueriesController`, with:
- `new` — a simple form with a text input for a question and a few
  clickable example queries (mix of obviously-canonical and obviously-
  exploratory questions, so the demo can show both paths firing)
- `create` — calls `SupportAgent#answer`, renders the result

The result view should clearly display:
- The question asked
- Which path answered it (a visible badge: "OKF — Curated" or "RAG —
  Retrieved", styled differently, e.g. green vs. blue)
- The answer text
- The source: for OKF, the concept title + resource link; for RAG, which
  chunks/tickets contributed
- A collapsible "show me the context that was sent to the model" section
  for transparency — this is the most important part of the demo, since
  the whole point is showing exactly what grounded the answer

Keep the styling simple and clean (system font stack, a little padding, a
couple of accent colors) — no need for a design system, just don't leave
it unstyled HTML.

## Step 7: Tests

Write RSpec request specs and unit specs covering:
- OkfConcept correctly parses frontmatter and body from a sample file
- KnowledgeRouter classifies a known canonical query as :okf and a known
  exploratory query as :rag (stub the LLM fallback call)
- KnowledgeChunk.search returns nearest neighbors given a stubbed embedding
- SupportAgent#answer returns the expected shape and stubs the Anthropic
  API call rather than hitting it in tests
- A request spec hitting QueriesController#create end to end with stubbed
  external API calls

## Step 8: README and production notes

Write a README that explains:
- What OKF and RAG are, briefly, and why this demo pairs them
- How to set up: Postgres + pgvector, env vars, bundle install, db setup,
  seeding the RAG chunks
- How to run it locally and try both query paths
- The file structure, especially where the OKF bundle lives and how to add
  a new concept to it
- A short "what would change for production" note: real auth, background
  job for embedding instead of inline seeding, labeled routing evals,
  classifier monitoring, rate limits, secret management, error handling,
  and telemetry for which path answers each query in production

## Constraints and preferences

- Prefer plain Ruby objects (POROs) for OkfConcept, EmbeddingClient,
  KnowledgeRouter, SupportAgent — don't force everything into
  ActiveRecord just because Rails makes that the path of least resistance
- Comment the router logic clearly since it's the conceptual heart of the
  demo
- Keep the runtime demoable with `rails server` and Postgres, but use
  production-shaped boundaries: small services, explicit configuration,
  external API failures handled clearly, and a README that explains the
  missing production pieces
- If the Anthropic Ruby SDK's gem name or API shape differs from what I've
  described, look it up and use the current correct version rather than
  guessing
- Ask me before making any assumption that would change the file structure
  described above; otherwise, use your best judgment and keep moving
```

---

## How to use this

Paste the whole block into Claude Code in one shot if you want it built end to end, or run it stage by stage (Step 1 → review → Step 2 → review) if you'd rather check in as it goes, especially around Step 2's OKF bundle content and Step 6's UI, since those are the two places demo quality lives or dies.

If Claude Code stalls or guesses wrong on the Anthropic Ruby SDK's current gem name/API shape, that's expected — it's flagged in the prompt on purpose so it looks it up instead of hallucinating an outdated interface.

## After it's built

A few natural next asks once the scaffold exists:
- "Add a comparison mode that runs the same query through OKF-only, RAG-only, and hybrid, side by side" — this is the single best way to *demo* why the hybrid wins, since you can literally show the RAG-only path guessing wrong on a canonical question
- "Add a small admin view to browse the OKF bundle as a graph" (concepts linking to concepts)
- "Log every query with which path answered it, so we can show a ratio of OKF vs. RAG hits over a demo session"
