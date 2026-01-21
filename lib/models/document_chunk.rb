# lib/models/document_chunk.rb
require_relative "../db"

class DocumentChunk < Sequel::Model(:document_chunks)
  plugin :pgvector, :embedding
end
