require_relative "../lib/db"
Sequel.extension :migration
Sequel::Migrator.run(DB, File.expand_path("migrations", __dir__))
puts "Migrations OK"