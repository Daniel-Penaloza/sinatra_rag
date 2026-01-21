Sequel.migration do
  change do
    create_table(:chat_sessions) do
      primary_key :id
      String :session_key, null: false, unique: true
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
    end
  end
end
