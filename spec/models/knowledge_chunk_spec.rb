require "rails_helper"

RSpec.describe KnowledgeChunk, type: :model do
  it "delegates vector search to neighbor with cosine distance" do
    relation = instance_double(ActiveRecord::Relation)
    embedding = Array.new(1536, 0.01)

    allow(described_class).to receive(:nearest_neighbors)
      .with(:embedding, embedding, distance: "cosine")
      .and_return(relation)
    allow(relation).to receive(:first).with(3).and_return(%w[a b c])

    expect(described_class.search(embedding, k: 3)).to eq(%w[a b c])
  end
end
