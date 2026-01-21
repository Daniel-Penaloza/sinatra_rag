require "openai"

module Services
  class Embeddings
    def initialize
      @client = OpenAI::Client.new(api_key: ENV.fetch("OPENAI_API_KEY"))
    end

    def embed(input_text)
      response = @client.embeddings.create(
        model: ENV.fetch("OPENAI_EMBEDDING_MODEL", "text-embedding-3-small"),
        input: input_text,
        encoding_format: 'float'
      )

      response.to_h[:data][0][:embedding]
    end
  end
end
