class Book < ApplicationRecord
  has_many :book_genres, dependent: :destroy
  has_many :genres, through: :book_genres

  validates :title, presence: true
  validate :isbns_are_unique_across_books

  # Serialize isbns as JSON array
  serialize :isbns, coder: JSON

  # Ensure isbns is always an array
  after_initialize :initialize_isbns

  scope :search, ->(query) {
    return all if query.blank?

    sanitized = "%#{sanitize_sql_like(query)}%"
    where(
      "title LIKE :q OR author LIKE :q OR isbns LIKE :q",
      q: sanitized
    )
  }

  scope :by_genre, ->(genre_name) {
    return all if genre_name.blank?

    # Find the genre and include all its children
    genre = Genre.find_by("LOWER(name) = LOWER(?)", genre_name.strip)
    return none unless genre

    # Get IDs of the genre and all its children
    genre_ids = [ genre.id ] + genre.children.pluck(:id)

    joins(:genres).where(genres: { id: genre_ids }).distinct
  }

  # Find a potential duplicate by title and author (case-insensitive)
  def self.find_duplicate(title, author)
    return nil if title.blank?

    scope = where("LOWER(title) = LOWER(?)", title.strip)
    scope = scope.where("LOWER(author) = LOWER(?)", author.strip) if author.present?
    scope.first
  end

  # Find a book that already has this ISBN
  def self.find_by_isbn(isbn)
    return nil if isbn.blank?

    normalized = normalize_isbn(isbn)
    where("isbns LIKE ?", "%#{normalized}%").find_each do |book|
      return book if book.isbns.any? { |i| normalize_isbn(i) == normalized }
    end
    nil
  end

  def self.normalize_isbn(isbn)
    isbn.to_s.strip.gsub(/[-\s]/, "")
  end

  # Add an ISBN if not already present
  def add_isbn(isbn)
    return if isbn.blank?

    normalized = self.class.normalize_isbn(isbn)
    self.isbns ||= []
    self.isbns << normalized unless isbns_include?(normalized)
  end

  # Check if ISBN already exists (normalized comparison)
  def isbns_include?(isbn)
    normalized = self.class.normalize_isbn(isbn)
    isbns.any? { |i| self.class.normalize_isbn(i) == normalized }
  end

  # Primary ISBN (first one)
  def primary_isbn
    isbns&.first
  end

  # Display ISBNs as comma-separated string
  def isbns_display
    isbns&.join(", ")
  end

  # Setter for single ISBN (for form compatibility)
  def isbn=(value)
    add_isbn(value)
  end

  # Getter for single ISBN (for form compatibility)
  def isbn
    primary_isbn
  end

  def genre_list
    genres.pluck(:name).join(", ")
  end

  def genre_list=(names)
    self.genres = names.split(",").map do |name|
      Genre.find_or_create_by_name(name.strip)
    end.compact
  end

  private

  def initialize_isbns
    self.isbns ||= [] if has_attribute?(:isbns)
  end

  def isbns_are_unique_across_books
    return if isbns.blank?

    isbns.each do |isbn|
      existing = self.class.find_by_isbn(isbn)
      if existing && existing.id != self.id
        errors.add(:isbns, "el ISBN #{isbn} ya existe en otro libro: #{existing.title}")
      end
    end
  end
end
