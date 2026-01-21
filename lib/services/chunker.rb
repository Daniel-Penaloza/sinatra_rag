module Services
  class Chunker
    def self.split(text, size: 1000, overlap: 150)
      t = text.gsub("\u0000", "").strip
      return [] if t.empty?

      chunks = []
      i = 0
      while i < t.length
        chunk = t[i, size]
        chunks << chunk.strip if chunk&.strip&.length&.positive?
        i += (size - overlap)
        break if size <= overlap
      end
      chunks
    end
  end
end
