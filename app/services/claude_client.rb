class ClaudeClient
  DEFAULT_MODEL = "claude-sonnet-4-6"

  def initialize(api_key: ENV["ANTHROPIC_API_KEY"], model: ENV.fetch("ANTHROPIC_MODEL", DEFAULT_MODEL))
    @api_key = api_key
    @model = model
  end

  def complete(system:, user:, max_tokens: 1000, model: @model)
    raise MissingConfiguration, "ANTHROPIC_API_KEY is required for Claude answers" if @api_key.blank?

    message = client.messages.create(
      model: model,
      max_tokens: max_tokens,
      system: system,
      messages: [ { role: "user", content: user } ]
    )

    extract_text(message)
  end

  private

  def client
    @client ||= Anthropic::Client.new(api_key: @api_key)
  end

  def extract_text(message)
    content = message.respond_to?(:content) ? message.content : message["content"]
    Array(content).filter_map do |block|
      block.respond_to?(:text) ? block.text : block["text"]
    end.join("\n").strip
  end

  class MissingConfiguration < StandardError; end
end
