class Book < ApplicationRecord
  has_many :book_genres, dependent: :destroy
  has_many :genres, through: :book_genres

  validates :title, presence: true
  validates :isbn, uniqueness: true, allow_blank: true

  scope :search, ->(query) {
    return all if query.blank?

    where(
      "title ILIKE :q OR author ILIKE :q OR isbn ILIKE :q",
      q: "%#{sanitize_sql_like(query)}%"
    )
  }

  scope :by_genre, ->(genre_name) {
    return all if genre_name.blank?

    joins(:genres).where("genres.name ILIKE ?", "%#{sanitize_sql_like(genre_name)}%")
  }

  def genre_list
    genres.pluck(:name).join(", ")
  end

  def genre_list=(names)
    self.genres = names.split(",").map do |name|
      Genre.find_or_create_by_name(name.strip)
    end.compact
  end
end
