module TextExtractors
  class TxtExtractor
    def self.extract(path)
      File.read(path).to_s.strip
    end
  end
end
