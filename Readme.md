# RAG desde cero con Ruby

**Haz que la IA responda con TU información, no con la de internet.**

---

## La idea

¿Alguna vez quisiste preguntarle algo a ChatGPT sobre tus propios documentos? Eso es exactamente lo que hace esta app.

Subes un PDF o TXT, la app lo "digiere" y después puedes hacerle preguntas como si fuera un experto en ese documento.

**Ejemplo real:**
- Subes el manual de tu empresa
- Preguntas: "¿Cuál es el proceso para solicitar vacaciones?"
- La IA te responde basándose SOLO en ese manual

---

## Tech Stack

| Qué hace | Tecnología |
|----------|------------|
| Backend | Ruby + Sinatra |
| Base de datos | PostgreSQL + pgvector |
| Procesamiento async | Sidekiq + Redis |
| Inteligencia | OpenAI (embeddings + chat) |

---

## Cómo funciona (sin complicarse)

### 1. Subes un documento

```
Tu PDF ──> La app lo guarda ──> Entra a la cola de procesamiento
```

### 2. La app lo procesa (en segundo plano)

```
Documento
    │
    ▼
Extrae el texto
    │
    ▼
Lo parte en pedazos pequeños (chunks)
    │
    ▼
Cada pedazo se convierte en números (embeddings)
    │
    ▼
Se guarda en la base de datos
```

**¿Por qué en pedazos?** Porque es más fácil buscar en fragmentos pequeños que en un documento de 100 páginas.

**¿Por qué números?** Porque las computadoras comparan números más rápido que texto. Y lo cool es que estos números capturan el *significado*, no solo las palabras.

### 3. Haces una pregunta

```
Tu pregunta
    │
    ▼
Se convierte en números (igual que los documentos)
    │
    ▼
Busca los pedazos más parecidos en la base de datos
    │
    ▼
Le pasa esos pedazos a la IA como contexto
    │
    ▼
La IA te responde basándose en TU información
```

---

## Levantando el proyecto

### Requisitos
- Docker (para la base de datos y Redis)
- Ruby 3.x
- Una API key de OpenAI

### 1. Clona y configura

```bash
git clone <este-repo>
cd RAG

# Crea tu archivo de variables de entorno
cp .env.example .env
# Edita .env y agrega tu OPENAI_API_KEY
```

### 2. Levanta los servicios

```bash
# Base de datos + Redis
docker-compose up -d

# Instala las gemas
bundle install

# Corre las migraciones
ruby db/migrate.rb
```

### 3. Arranca la app

Necesitas dos terminales:

```bash
# Terminal 1 - Sidekiq (procesa documentos)
bundle exec sidekiq -r ./config/sidekiq.rb

# Terminal 2 - Web app
ruby app.rb
```

### 4. Abre tu navegador

- **http://localhost:4567/upload** - Sube documentos
- **http://localhost:4567/chat** - Hazle preguntas

---

## Estructura del proyecto

```
RAG/
├── app.rb                 # El cerebro de la app (rutas)
├── config/
│   └── sidekiq.rb         # Config de jobs en background
├── db/
│   └── migrations/        # Estructura de la base de datos
├── lib/
│   ├── jobs/
│   │   └── document_processor_job.rb  # Procesa docs en segundo plano
│   ├── models/            # Tablas de la BD
│   ├── services/
│   │   ├── chat_agent.rb      # El que arma las respuestas
│   │   ├── chunker.rb         # Parte el texto en pedazos
│   │   ├── embeddings.rb      # Convierte texto a números
│   │   └── rag_retriever.rb   # Busca los pedazos relevantes
│   └── text_extractors/   # Saca texto de PDFs y TXTs
├── views/                 # Las pantallas de la app
└── docker-compose.yml     # PostgreSQL + Redis
```

---

## Las piezas clave

### El Chunker (divide y vencerás)

Imagina que tienes un libro de 200 páginas. Si alguien te pregunta algo, no le lees todo el libro. Buscas la parte relevante.

El chunker hace exactamente eso: parte el documento en fragmentos manejables (como párrafos grandes) con un poco de traslape para no perder contexto.

### Los Embeddings (el traductor mágico)

Aquí está la magia real. Cada pedazo de texto se convierte en una lista de números que representa su *significado*.

Textos similares = números similares.

Así, cuando preguntas algo, tu pregunta también se convierte en números y buscamos los chunks cuyos números se parecen más.

### El RAG Retriever (el buscador)

Usa la base de datos vectorial (PostgreSQL + pgvector) para encontrar los chunks más similares a tu pregunta. Es como un buscador, pero que entiende significado, no solo palabras.

### El Chat Agent (el que responde)

Toma los chunks encontrados, se los pasa a la IA como contexto, y le dice:
> "Responde esta pregunta usando SOLO esta información. Si no está la respuesta, dilo."

---

## Limitaciones (siendo honestos)

- **PDFs escaneados no funcionan** - Necesitarías OCR para eso
- **Archivos muy grandes** - Pueden tardar en procesarse
- **Límite de 10MB** por archivo
- **Solo PDF y TXT** por ahora

---

## ¿Por qué hice esto?

Quería entender cómo funciona RAG sin usar frameworks como LangChain que esconden todo. 

Construirlo desde cero me ayudó a entender cada pieza del rompecabezas. Y ahora tú también puedes entenderlo.

No es producción-ready, pero es 100% educativo y funcional.

---

## Variables de entorno

```bash
OPENAI_API_KEY=tu-api-key-aqui
DATABASE_URL=postgres://rag:rag@localhost:5432/rag_demo
REDIS_URL=redis://localhost:6379/0
```

---

## Próximos pasos (ideas)

- [ ] Soporte para más formatos (Word, Markdown)
- [ ] OCR para PDFs escaneados
- [ ] Mejor UI con algo como Tailwind
- [ ] Historial de conversaciones más elaborado
- [ ] Filtrar por documento específico al preguntar

---

**Hecho con Ruby y curiosidad.**