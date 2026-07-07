require "rails_helper"

RSpec.describe OkfConcept do
  it "parses frontmatter and markdown body" do
    concept = described_class.parse(Rails.root.join("knowledge/policies/refund-window.md"))

    expect(concept.type).to eq("policy")
    expect(concept.title).to eq("Refund Window")
    expect(concept.tags).to include("refund", "billing")
    expect(concept.body).to include("14 calendar days")
  end

  it "returns a lightweight bundle map" do
    bundle_map = described_class.map

    expect(bundle_map).to include(hash_including(title: "Refund Window", type: "policy"))
  end
end
