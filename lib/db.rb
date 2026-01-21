require 'sequel'
require 'pg'
require 'pgvector'
require 'dotenv/load'

# Conexion a la base de datos
DB = Sequel.connect(ENV['DATABASE_URL'])

# Extensiones utiles para Sequel
DB.extension :pg_json
DB.extension :pagination

# pgvector: registra el tipo de vector
Sequel.extension :pgvector

