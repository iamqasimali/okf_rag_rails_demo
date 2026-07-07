class CreateKnowledgeChunks < ActiveRecord::Migration[8.1]
  def change
    create_table :knowledge_chunks do |t|
      t.text :content, null: false
      t.string :source, null: false
      t.vector :embedding, limit: 1536, null: false

      t.timestamps
    end

    add_index :knowledge_chunks, :source
    add_index :knowledge_chunks, :embedding, using: :hnsw, opclass: :vector_cosine_ops
  end
end
