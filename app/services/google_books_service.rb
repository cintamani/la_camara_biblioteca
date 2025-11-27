require "net/http"
require "json"
require "openssl"

class GoogleBooksService
  BASE_URL = "https://www.googleapis.com/books/v1/volumes".freeze

  class BookNotFoundError < StandardError; end
  class ApiError < StandardError; end

  def self.fetch_by_isbn(isbn)
    new.fetch_by_isbn(isbn)
  end

  def fetch_by_isbn(isbn)
    cleaned_isbn = isbn.to_s.gsub(/[^0-9X]/i, "")
    return nil if cleaned_isbn.blank?

    uri = URI("#{BASE_URL}?q=isbn:#{cleaned_isbn}")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http.cert_store = OpenSSL::X509::Store.new.tap(&:set_default_paths)

    request = Net::HTTP::Get.new(uri)
    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      raise ApiError, "Google Books API returned status #{response.code}"
    end

    data = JSON.parse(response.body)

    if data["totalItems"].to_i.zero?
      raise BookNotFoundError, "No book found for ISBN: #{isbn}"
    end

    parse_book_data(data["items"].first, cleaned_isbn)
  end

  private

  def parse_book_data(item, isbn)
    volume_info = item["volumeInfo"] || {}

    {
      title: volume_info["title"],
      author: extract_authors(volume_info["authors"]),
      isbn: isbn,
      genres: extract_categories(volume_info["categories"])
    }
  end

  def extract_authors(authors)
    return nil if authors.blank?
    authors.join(", ")
  end

  def extract_categories(categories)
    return [] if categories.blank?
    categories.map(&:strip)
  end
end
