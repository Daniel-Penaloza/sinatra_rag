module Config
  CHUNK_SIZE = ENV.fetch('RAG_CHUNK_SIZE', 1100).to_i
  CHUNK_OVERLAP = ENV.fetch('RAG_CHUNK_OVERLAP', 200).to_i
  RETRIEVAL_TOP_K = ENV.fetch('RAG_TOP_K', 6).to_i
  MAX_FILE_SIZE = ENV.fetch('MAX_FILE_SIZE', 10_485_760).to_i
  
  OPENAI_CHAT_MODEL = ENV.fetch('OPENAI_CHAT_MODEL', 'gpt-4o-mini')
  OPENAI_EMBEDDING_MODEL = ENV.fetch('OPENAI_EMBEDDING_MODEL', 'text-embedding-3-small')
end