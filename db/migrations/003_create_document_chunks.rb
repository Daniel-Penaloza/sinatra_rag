Sequel.migration do
  change do
    create_table(:document_chunks) do
      primary_key :id
      foreign_key :document_id, :documents, null: false, on_delete: :cascade

      Integer :chunk_index, null: false
      Text :content, null: false

      # pgvector type - text-embedding-3-small uses 1536 dims.
      column :embedding, "vector(1536)", null: false

      Integer :char_count, null: false, default: 0
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      index [:document_id, :chunk_index], unique: true
    end

    # Índice vectorial (ivfflat). Requiere ANALYZE después de insertar datos.
    run "CREATE INDEX document_chunks_embedding_ivfflat ON document_chunks USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100)"
  end
end
