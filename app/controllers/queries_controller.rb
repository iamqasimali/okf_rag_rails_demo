class QueriesController < ApplicationController
  EXAMPLES = [
    "Can I get a refund after renewing Flowbase yesterday?",
    "How much does Growth cost if we need 14 seats?",
    "How long are automation run logs retained on Enterprise?",
    "A customer's Slack approval step keeps timing out after OAuth reconnect. What worked before?",
    "Have customers reported CSV exports losing timezone information?"
  ].freeze

  rescue_from EmbeddingClient::MissingConfiguration, ClaudeClient::MissingConfiguration, with: :missing_configuration

  def new
    @examples = EXAMPLES
  end

  def create
    @examples = EXAMPLES
    @question = params[:query].to_s.strip

    if @question.blank?
      flash.now[:alert] = "Enter a question."
      render_result(status: :unprocessable_content)
      return
    end

    @result = SupportAgent.new.answer(@question)
    render_result
  end

  private

  def missing_configuration(error)
    @examples = EXAMPLES
    @question = params[:query].to_s
    @configuration_error = error.message
    render_result(status: :service_unavailable)
  end

  def render_result(status: :ok)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "chat_result",
          partial: "queries/result",
          locals: {
            result: @result,
            alert: flash.now[:alert],
            configuration_error: @configuration_error
          }
        ), status: status
      end

      format.html { render :new, status: status }
    end
  end
end
