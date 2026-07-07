require "rails_helper"

RSpec.describe SupportAgent do
  it "returns answer text, route metadata, sources, and model context" do
    concept = OkfConcept.parse(Rails.root.join("knowledge/pricing/plans.md"))
    router = instance_double(KnowledgeRouter)
    claude = instance_double(ClaudeClient)

    allow(router).to receive(:call).and_return(
      source: :okf,
      concepts: [ concept ],
      route_reason: "Rule matched curated OKF tags."
    )
    allow(claude).to receive(:complete).and_return("This came from curated policy: Growth costs USD 99.")

    result = described_class.new(router: router, claude_client: claude).answer("What does Growth cost?")

    expect(result[:answer]).to include("curated policy")
    expect(result[:source]).to eq(:okf)
    expect(result[:sources]).to include(hash_including(title: "Plans", resource: "flowbase://pricing/plans"))
    expect(result[:context]).to include("[OKF: Plans]")
  end
end
