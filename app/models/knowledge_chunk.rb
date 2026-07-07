class KnowledgeChunk < ApplicationRecord
  has_neighbors :embedding

  validates :content, :source, :embedding, presence: true

  def self.search(query_embedding, k: 5)
    nearest_neighbors(:embedding, query_embedding, distance: "cosine").first(k)
  end
end
