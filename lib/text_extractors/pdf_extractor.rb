require "pdf/reader"

module TextExtractors
  class PdfExtractor
    def self.extract(path)
      reader = PDF::Reader.new(path)
      text = reader.pages.map(&:text).join("\n")
      text.strip
    end
  end
end
