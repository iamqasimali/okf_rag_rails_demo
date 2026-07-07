namespace :rag do
  def embed_and_insert(snippets, batch_size: 100)
    abort "OPENAI_API_KEY is required to seed RAG chunks." if ENV["OPENAI_API_KEY"].blank?

    inserted = RagSeeder.new(batch_size: batch_size).seed(snippets)
    puts "Inserted #{inserted} chunks; total is now #{KnowledgeChunk.count}."
  end

  desc "Embed and seed the base demo support-history chunks"
  task seed_base: :environment do
    embed_and_insert(RagSeedData.base)
    puts "Seeded #{KnowledgeChunk.count} knowledge chunks."
  end

  desc "Alias for rag:seed_base"
  task seed: :seed_base

  desc "Embed and seed a larger synthetic support-history corpus. Usage: bin/rails 'rag:seed_large[300]'"
  task :seed_large, [ :count ] => :environment do |_task, args|
    count = args[:count].presence&.to_i || 300
    abort "Count must be positive." if count <= 0

    embed_and_insert(RagSeedData.generated(count))
    puts "Seeded #{KnowledgeChunk.count} total knowledge chunks."
  end
end
