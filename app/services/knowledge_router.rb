class KnowledgeRouter
  OKF_THRESHOLD = 1
  TAG_SYNONYMS = {
    "refund" => %w[refund refunded reimbursement cancel cancellation credit],
    "pricing" => %w[pricing price cost costs plan plans seat seats billing upgrade downgrade],
    "retention" => %w[retention retain deleted backup backups logs privacy data compliance],
    "escalation" => %w[escalation escalate urgent security incident outage p1 sla support]
  }.freeze

  def self.call(query, **kwargs)
    new(**kwargs).call(query)
  end

  def initialize(okf_concepts: OkfConcept.load_all, embedding_client: EmbeddingClient.new, claude_client: ClaudeClient.new, rag_k: 5)
    @okf_concepts = okf_concepts
    @embedding_client = embedding_client
    @claude_client = claude_client
    @rag_k = rag_k
  end

  def call(query)
    query = query.to_s.strip
    matches = rule_matches(query)

    if matches.any?
      return { source: :okf, concepts: matches, route_reason: "Rule matched curated OKF tags." }
    end

    if fallback_classification(query) == :okf
      return { source: :okf, concepts: fallback_concepts(query), route_reason: "Claude classifier selected OKF." }
    end

    embedding = @embedding_client.embed(query)
    {
      source: :rag,
      chunks: KnowledgeChunk.search(embedding, k: @rag_k),
      route_reason: "No curated OKF tag matched; retrieved support history."
    }
  end

  private

  def rule_matches(query)
    tokens = normalized_tokens(query)
    scored = @okf_concepts.map do |concept|
      terms = concept.tags + concept.title.downcase.scan(/[a-z0-9]+/)
      expanded = terms.flat_map { |term| TAG_SYNONYMS.fetch(term, [ term ]) }
      [ concept, (tokens & expanded).size ]
    end

    matches = scored.select { |_concept, score| score >= OKF_THRESHOLD }
      .sort_by { |_concept, score| -score }
      .map(&:first)
      .first(3)

    policy_matches = matches.select { |concept| concept.type == "policy" }
    policy_matches.presence || matches
  end

  def fallback_classification(query)
    labels = @okf_concepts.map(&:to_map).map { |item| "#{item[:title]}: #{item[:tags].join(", ")}" }.join("\n")
    response = @claude_client.complete(
      max_tokens: 8,
      system: "Return exactly one lowercase token: okf or rag.",
      user: <<~PROMPT
        Query: #{query}

        Available curated OKF concepts:
        #{labels}

        Use okf only when the query asks for a canonical policy, pricing, support escalation, or data retention answer.
        Use rag for troubleshooting, anecdotes, vague edge cases, and support history.
      PROMPT
    )

    response.to_s.downcase.include?("okf") ? :okf : :rag
  rescue ClaudeClient::MissingConfiguration
    :rag
  end

  def fallback_concepts(query)
    rule_matches(query).presence || OkfConcept.find_by_type("policy", concepts: @okf_concepts).first(3)
  end

  def normalized_tokens(query)
    query.downcase.scan(/[a-z0-9]+/)
  end
end
