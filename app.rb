# app.rb
require "sinatra"
require "securerandom"
require "fileutils"
require "json"
require "byebug"

require_relative "lib/db"
require_relative "lib/text_extractors/pdf_extractor"
require_relative "lib/text_extractors/txt_extractor"
require_relative "lib/services/chunker"
require_relative "lib/services/embeddings"
require_relative "lib/services/rag_retriever"
require_relative "lib/services/chat_agent"
require_relative "lib/models/document"
require_relative "lib/models/document_chunk"

Dir[File.join(__dir__, "lib/models/**/*.rb")].each do |file|
  require file
end

set :bind, "0.0.0.0"
set :port, 4567
set :public_folder, File.expand_path("public", __dir__)

UPLOAD_DIR = File.expand_path("public/uploads", __dir__)
FileUtils.mkdir_p(UPLOAD_DIR)

helpers do
  def db = DB

  def find_or_create_chat_session
    key = request.cookies["chat_session_key"]
    if key.nil? || key.strip.empty?
      key = SecureRandom.uuid
      response.set_cookie("chat_session_key", value: key, path: "/", httponly: true)
    end

    row = db[:chat_sessions].where(session_key: key).first
    if row.nil?
      id = db[:chat_sessions].insert(session_key: key)
      row = db[:chat_sessions].where(id: id).first
    end
    row
  end

  def allowed_file?(filename, mime)
    ext = File.extname(filename).downcase
    return true if ext == ".pdf" && mime == "application/pdf"
    return true if ext == ".txt" && (mime == "text/plain" || mime.nil? || mime.empty?)
    false
  end
end

get "/" do
  redirect "/upload"
end

# 1) Vista para cargar documentos
get "/upload" do
  @documents = db[:documents].reverse_order(:id).all
  erb :upload
end

post "/documents" do
  file = params[:file]
  halt 400, "Falta archivo" if file.nil?

  filename = file[:filename]
  tempfile = file[:tempfile]
  mime = file[:type]

  halt 400, "Solo PDF o TXT" unless allowed_file?(filename, mime)

  storage_name = "#{SecureRandom.uuid}#{File.extname(filename).downcase}"
  storage_path = File.join(UPLOAD_DIR, storage_name)
  FileUtils.cp(tempfile.path, storage_path)

  title = params[:title].to_s.strip
  title = filename if title.empty?

  doc_id = db[:documents].insert(
    title: title,
    filename: filename,
    content_type: mime.to_s,
    storage_path: storage_path
  )

  # extraer texto
  text =
    if File.extname(filename).downcase == ".pdf"
      TextExtractors::PdfExtractor.extract(storage_path)
    else
      TextExtractors::TxtExtractor.extract(storage_path)
    end

  halt 400, "El documento no contiene texto (¿PDF escaneado?)" if text.strip.empty?

  chunks = Services::Chunker.split(text, size: 1100, overlap: 200)
  embedder = Services::Embeddings.new

  chunks.each_with_index do |chunk, idx|
    emb = embedder.embed(chunk)
    next if emb.nil?

    DocumentChunk.create(
      document_id: doc_id,
      chunk_index: idx,
      content: chunk,
      embedding: emb,          # ✅ Array<Float>
      char_count: chunk.length
    )

  end

  # Recomendado para ivfflat tras insertar: ANALYZE - indice de busqueda aproximada de vecinos
  db.run("ANALYZE document_chunks")

  redirect "/upload"
end

# 2) Vista de chat
get "/chat" do
  session = find_or_create_chat_session
  @messages = db[:chat_messages].where(chat_session_id: session[:id]).order(:id).all
  erb :chat
end

post "/chat" do
  session = find_or_create_chat_session
  question = params[:message].to_s.strip
  halt 400, "Mensaje vacío" if question.empty?

  db[:chat_messages].insert(chat_session_id: session[:id], role: "user", content: question, sources: Sequel.pg_jsonb([]))

  agent = Services::ChatAgent.new
  result = agent.answer(question)

  db[:chat_messages].insert(
    chat_session_id: session[:id],
    role: "assistant",
    content: result[:answer],
    sources: Sequel.pg_jsonb(result[:sources])
  )

  redirect "/chat"
end
