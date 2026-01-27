require "openai"
require_relative "../config"

module Services
  class Embeddings
    def initialize
      @client = OpenAI::Client.new(api_key: ENV.fetch("OPENAI_API_KEY"))
    end

    def embed(input_text)
      response = @client.embeddings.create(
        model: Config::OPENAI_EMBEDDING_MODEL,
        input: input_text,
        encoding_format: 'float'
      )

      response.to_h[:data][0][:embedding]
    end
  end
end
