# Architecture

Flowbase demonstrates a hybrid knowledge agent with two grounding layers:

- OKF for canonical, curated answers that should not be improvised.
- RAG for support-history retrieval across messy, unstructured cases.

## Request Flow

1. `QueriesController#create` receives the question.
2. `SupportAgent#answer` asks `KnowledgeRouter` which source should answer.
3. `KnowledgeRouter` checks curated OKF tags first.
4. If rules do not match, the router asks Claude for a strict `okf` or `rag`
   fallback classification.
5. OKF routes load markdown concept bodies through `OkfConcept`.
6. RAG routes embed the query with `EmbeddingClient` and call
   `KnowledgeChunk.search`.
7. `SupportAgent` builds the exact context sent to Claude.
8. The UI displays the answer, route badge, sources, and model context.

## Main Objects

- `OkfConcept`: filesystem parser for the `/knowledge` markdown bundle.
- `KnowledgeChunk`: ActiveRecord model backed by `pgvector`.
- `EmbeddingClient`: OpenAI embeddings wrapper using `text-embedding-3-small`.
- `ClaudeClient`: Anthropic SDK wrapper for classifier and answer calls.
- `KnowledgeRouter`: rules-first source selection plus Claude fallback.
- `SupportAgent`: context builder and final answer orchestration.
- `RagSeedData`: base and generated support-history snippets.
- `RagSeeder`: batched embedding and insert service for seed tasks.

## Production Shape

The current app is demo-sized, but the key production boundaries are separate:
content parsing, retrieval, routing, and answer generation. In production, add
auth, rate limits, background embedding jobs, retryable API clients, route
telemetry, labeled classifier evaluation, and content review workflows for OKF.

See `doc/extending-knowledge.md` for the practical workflow to add new OKF
concepts and RAG chunks.
