require "rails_helper"

RSpec.describe EmbeddingClient do
  it "returns embeddings in response index order" do
    client = described_class.new(api_key: "test-key")
    response = http_response({
      data: [
        { index: 1, embedding: [ 0.2, 0.3 ] },
        { index: 0, embedding: [ 0.1, 0.4 ] }
      ]
    }.to_json, success: true)

    allow(Net::HTTP).to receive(:post).and_return(response)

    expect(client.embed_many(%w[first second])).to eq([ [ 0.1, 0.4 ], [ 0.2, 0.3 ] ])
  end

  it "raises a clear error when the API returns non-JSON" do
    client = described_class.new(api_key: "test-key")

    allow(Net::HTTP).to receive(:post).and_return(http_response("bad gateway", success: false))

    expect { client.embed("hello") }.to raise_error(
      described_class::ApiError,
      "OpenAI embeddings response was not valid JSON"
    )
  end

  it "raises a clear error when a successful response omits embeddings data" do
    client = described_class.new(api_key: "test-key")

    allow(Net::HTTP).to receive(:post).and_return(http_response({}.to_json, success: true))

    expect { client.embed("hello") }.to raise_error(
      described_class::ApiError,
      /Malformed OpenAI embeddings response/
    )
  end

  def http_response(body, success:)
    Struct.new(:body, :success) do
      def is_a?(klass)
        klass == Net::HTTPSuccess ? success : super
      end
    end.new(body, success)
  end
end
