class SupportAgent
  SYSTEM_PROMPT = <<~PROMPT.squish
    You are Flowbase's support knowledge agent. Answer using only the provided context.
    If the context is insufficient, say what is missing instead of guessing.
    State whether the answer came from "curated policy" or "retrieved support history".
    Include concise citations from the supplied source labels.
  PROMPT

  def initialize(router: KnowledgeRouter, claude_client: ClaudeClient.new)
    @router = router
    @claude_client = claude_client
  end

  def answer(query)
    route = @router.call(query)
    context = build_context(route)
    answer_text = @claude_client.complete(
      system: SYSTEM_PROMPT,
      user: "Question: #{query}\n\nContext:\n#{context}",
      max_tokens: 1000
    )

    {
      question: query,
      answer: answer_text,
      source: route.fetch(:source),
      sources: source_metadata(route),
      context: context,
      route_reason: route[:route_reason]
    }
  end

  private

  def build_context(route)
    if route.fetch(:source) == :okf
      route.fetch(:concepts).map do |concept|
        <<~TEXT
          [OKF: #{concept.title}]
          Resource: #{concept.resource}
          Path: #{concept.path}
          #{concept.body}
        TEXT
      end.join("\n---\n")
    else
      route.fetch(:chunks).map do |chunk|
        <<~TEXT
          [RAG: #{chunk.source}]
          #{chunk.content}
        TEXT
      end.join("\n---\n")
    end
  end

  def source_metadata(route)
    if route.fetch(:source) == :okf
      route.fetch(:concepts).map { |concept| { title: concept.title, resource: concept.resource, path: concept.path } }
    else
      route.fetch(:chunks).map { |chunk| { source: chunk.source, id: chunk.id } }
    end
  end
end
