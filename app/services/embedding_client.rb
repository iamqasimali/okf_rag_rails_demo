require "json"
require "net/http"

class EmbeddingClient
  DEFAULT_MODEL = "text-embedding-3-small"
  DIMENSIONS = 1536

  def initialize(api_key: ENV["OPENAI_API_KEY"], model: ENV.fetch("OPENAI_EMBEDDING_MODEL", DEFAULT_MODEL))
    @api_key = api_key
    @model = model
  end

  def embed(text)
    embed_many([ text ]).first
  end

  def embed_many(texts)
    raise MissingConfiguration, "OPENAI_API_KEY is required for embeddings" if @api_key.blank?

    response = Net::HTTP.post(
      URI("https://api.openai.com/v1/embeddings"),
      { model: @model, input: texts }.to_json,
      {
        "Authorization" => "Bearer #{@api_key}",
        "Content-Type" => "application/json"
      }
    )

    body = parse_response_body(response)
    raise ApiError, body.dig("error", "message") || "OpenAI embeddings request failed" unless response.is_a?(Net::HTTPSuccess)

    body.fetch("data").sort_by { |item| item.fetch("index") }.map { |item| item.fetch("embedding") }
  rescue KeyError => error
    raise ApiError, "Malformed OpenAI embeddings response: #{error.message}"
  end

  private

  def parse_response_body(response)
    JSON.parse(response.body)
  rescue JSON::ParserError
    raise ApiError, "OpenAI embeddings response was not valid JSON"
  end

  class MissingConfiguration < StandardError; end
  class ApiError < StandardError; end
end
