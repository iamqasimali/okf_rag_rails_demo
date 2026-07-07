unless ENV["OPENAI_API_KEY"].present?
  puts "Skipping RAG seed embeddings because OPENAI_API_KEY is not set."
  return
end

inserted = RagSeeder.new.seed(RagSeedData.base)
puts "Inserted #{inserted} base RAG chunks; total is now #{KnowledgeChunk.count}."
