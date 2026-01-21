Sequel.migration do
  change do
    create_table(:chat_messages) do
      primary_key :id
      foreign_key :chat_session_id, :chat_sessions, null: false, on_delete: :cascade

      String :role, null: false # "user" | "assistant"
      Text :content, null: false
      jsonb :sources, null: false, default: Sequel.pg_jsonb([])

      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      index :chat_session_id
    end
  end
end
