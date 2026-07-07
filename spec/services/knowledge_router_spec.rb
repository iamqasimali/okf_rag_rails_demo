require "rails_helper"

RSpec.describe KnowledgeRouter do
  let(:embedding_client) { instance_double(EmbeddingClient, embed: Array.new(1536, 0.02)) }
  let(:claude_client) { instance_double(ClaudeClient, complete: "rag") }

  it "classifies canonical policy queries as OKF" do
    result = described_class.call(
      "What is the refund window?",
      embedding_client: embedding_client,
      claude_client: claude_client
    )

    expect(result[:source]).to eq(:okf)
    expect(result[:concepts].map(&:title)).to include("Refund Window")
    expect(result[:concepts].map(&:type).uniq).to eq([ "policy" ])
    expect(embedding_client).not_to have_received(:embed)
  end

  it "classifies exploratory support-history queries as RAG" do
    chunks = [ instance_double(KnowledgeChunk, source: "TICKET-1001", content: "Slack timeout fix") ]
    allow(KnowledgeChunk).to receive(:search).and_return(chunks)

    result = described_class.call(
      "The Slack approval step times out after reconnecting OAuth. Any prior fix?",
      embedding_client: embedding_client,
      claude_client: claude_client
    )

    expect(result[:source]).to eq(:rag)
    expect(result[:chunks]).to eq(chunks)
    expect(KnowledgeChunk).to have_received(:search).with(Array.new(1536, 0.02), k: 5)
  end
end
