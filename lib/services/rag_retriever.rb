# lib/services/rag_retriever.rb
require_relative "../models/document_chunk"

module Services
  class RagRetriever
    def initialize(embedder: Services::Embeddings.new)
      @embedder = embedder
    end

    # regresa top_k chunks con distance + metadata
    def retrieve(question, top_k: 6)
      q_emb = @embedder.embed(question)
      raise "No se pudo generar embedding" if q_emb.nil?

      # nearest_neighbors ya ordena por similitud y agrega columna de distancia.
      # distance: "cosine" => menor distance = más similar
      DocumentChunk
        .nearest_neighbors(:embedding, q_emb, distance: "cosine")
        .select(
          Sequel[:document_chunks][:id].as(:chunk_id),
          Sequel[:document_chunks][:document_id],
          Sequel[:document_chunks][:chunk_index],
          Sequel[:document_chunks][:content]
        )
        .limit(top_k)
        .all
    end
  end
end
