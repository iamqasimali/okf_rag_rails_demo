require "rails_helper"

RSpec.describe RagSeedData do
  it "generates deterministic synthetic snippets with stable sources" do
    snippets = described_class.generated(2)

    expect(snippets.size).to eq(2)
    expect(snippets.first.first).to eq("LOAD-00001")
    expect(snippets.first.second).to include("support-history note")
  end
end
