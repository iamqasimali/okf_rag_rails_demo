require "rails_helper"

RSpec.describe RagSeeder do
  it "embeds pending snippets in batches and inserts rows" do
    embedding_client = instance_double(EmbeddingClient)
    snippets = [
      [ "LOAD-00001", "First support note" ],
      [ "LOAD-00002", "Second support note" ]
    ]

    allow(KnowledgeChunk).to receive(:exists?).and_return(false)
    allow(KnowledgeChunk).to receive(:insert_all!)
    allow(embedding_client).to receive(:embed_many)
      .with([ "First support note", "Second support note" ])
      .and_return([ Array.new(1536, 0.01), Array.new(1536, 0.02) ])

    inserted = described_class.new(embedding_client: embedding_client, batch_size: 10).seed(snippets)

    expect(inserted).to eq(2)
    expect(KnowledgeChunk).to have_received(:insert_all!).with(array_including(hash_including(source: "LOAD-00001")))
  end
end
