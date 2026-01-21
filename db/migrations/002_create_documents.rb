Sequel.migration do
  change do
    create_table(:documents) do
      primary_key :id
      String :title, null: false
      String :filename, null: false
      String :content_type, null: false # application/pdf, text/plain
      String :storage_path, null: false
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
    end
  end
end
