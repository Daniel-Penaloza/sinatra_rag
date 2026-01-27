require "sidekiq"
require_relative "../services/chunker"
require_relative "../services/embeddings"
require_relative "../models/document_chunk"
require_relative "../text_extractors/pdf_extractor"
require_relative "../text_extractors/txt_extractor"
require_relative "../db"

module Jobs
  class DocumentProcessorJob
    include Sidekiq::Worker
    sidekiq_options queue: :default, retry: 3
    
    def perform(doc_id, storage_path, filename)

      # Extraer texto del documento
      text = 
        if File.extname(filename).downcase == ".pdf"
          TextExtractors::PdfExtractor.extract(storage_path)
        else
          TextExtractors::TxtExtractor.extract(storage_path)
        end

        return if text.strip.empty?

        # Chunking - Embeddings
        chunks = Services::Chunker.split(text, size: 1100, overlap: 200)
        embedder = Services::Embeddings.new

        chunks.each_with_index do |chunk, idx|
          emb = embedder.embed(chunk)
          next if emb.nil?
  
          DocumentChunk.create(
            document_id: doc_id,
            chunk_index: idx,
            content: chunk,
            embedding: emb,
            char_count: chunk.length
          )
        end
  
        DB.run("ANALYZE document_chunks")
    end
  end
end
