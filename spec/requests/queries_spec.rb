require "rails_helper"

RSpec.describe "Queries", type: :request do
  it "answers a query through the support agent" do
    result = {
      question: "What is the refund window?",
      answer: "This came from curated policy: 14 calendar days.",
      source: :okf,
      sources: [ { title: "Refund Window", resource: "flowbase://policies/refund-window", path: "policies/refund-window.md" } ],
      context: "[OKF: Refund Window]\n14 calendar days",
      route_reason: "Rule matched curated OKF tags."
    }

    agent = instance_double(SupportAgent, answer: result)
    allow(SupportAgent).to receive(:new).and_return(agent)

    post queries_path, params: { query: "What is the refund window?" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("OKF - Curated")
    expect(response.body).to include("14 calendar days")
    expect(agent).to have_received(:answer).with("What is the refund window?")
  end

  it "updates the result frame for turbo stream submissions" do
    result = {
      question: "What is the refund window?",
      answer: "This came from curated policy: 14 calendar days.",
      source: :okf,
      sources: [ { title: "Refund Window", resource: "flowbase://policies/refund-window", path: "policies/refund-window.md" } ],
      context: "[OKF: Refund Window]\n14 calendar days",
      route_reason: "Rule matched curated OKF tags."
    }

    allow(SupportAgent).to receive(:new).and_return(instance_double(SupportAgent, answer: result))

    post queries_path,
      params: { query: "What is the refund window?" },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(response.body).to include('<turbo-stream action="update" target="chat_result">')
    expect(response.body).to include("OKF - Curated")
  end

  it "renders validation feedback for a blank query" do
    post queries_path, params: { query: "" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Enter a question.")
  end
end
