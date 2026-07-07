class RagSeeder
  DEFAULT_BATCH_SIZE = 100

  def initialize(embedding_client: EmbeddingClient.new, batch_size: DEFAULT_BATCH_SIZE)
    @embedding_client = embedding_client
    @batch_size = batch_size
  end

  def seed(snippets)
    pending = snippets.reject { |source, _content| KnowledgeChunk.exists?(source: source) }
    inserted = 0

    pending.each_slice(@batch_size) do |batch|
      embeddings = @embedding_client.embed_many(batch.map(&:second))
      rows = batch.zip(embeddings).map do |(source, content), embedding|
        {
          source: source,
          content: content,
          embedding: embedding,
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      KnowledgeChunk.insert_all!(rows) if rows.any?
      inserted += rows.size
    end

    inserted
  end
end
