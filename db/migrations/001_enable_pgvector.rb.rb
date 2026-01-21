Sequel.migration do
  change do
    run "CREATE EXTENSION IF NOT EXISTS vector"
  end
end
