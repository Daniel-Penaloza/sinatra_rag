require "openai"
require_relative "../config"

module Services
  class ChatAgent
    SYSTEM = <<~SYS
      Eres un asistente que responde usando SOLO el CONTEXTO proporcionado.
      - Si el contexto no contiene la respuesta, di claramente: "No tengo suficiente información en los documentos."
      - Devuelve una sección "Fuentes" listando doc_id y chunk_id usados.
      - Sé conciso y directo.
    SYS

    def initialize(retriever: Services::RagRetriever.new)
      @retriever = retriever
      @client = OpenAI::Client.new(api_key: ENV.fetch("OPENAI_API_KEY"))
    end

    def answer(question)
      hits = @retriever.retrieve(question, top_k: 6)

      context = hits.map.with_index(1) do |h, idx|
        "[S#{idx}] doc_id=#{h[:document_id]} chunk_id=#{h[:chunk_id]} chunk_index=#{h[:chunk_index]}\n#{h[:content]}"
      end.join("\n\n")

      user_prompt = <<~USR
        CONTEXTO:
        #{context}

        PREGUNTA:
        #{question}
      USR


      resp = @client.chat.completions.create(
        model: Config::OPENAI_CHAT_MODEL,
        messages: [
          { 
            role: "system",
            content: SYSTEM
          },
          { 
            role: "user", 
            content: user_prompt 
          }
        ]
      )

      h = resp.respond_to?(:to_h) ? resp.to_h : resp

      content = h[:choices]&.first&.message&.[](:content)
      {
        answer: content.to_s.strip,
        sources: hits.map { |x| { doc_id: x[:document_id], chunk_id: x[:chunk_id], distance: x[:distance] } }
      }
    end
  end
end
