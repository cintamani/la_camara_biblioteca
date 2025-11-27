class Genre < ApplicationRecord
  belongs_to :parent, class_name: "Genre", optional: true
  has_many :children, class_name: "Genre", foreign_key: :parent_id, dependent: :destroy

  has_many :book_genres, dependent: :destroy
  has_many :books, through: :book_genres

  validates :name, presence: true, uniqueness: { scope: :parent_id, case_sensitive: false }
  validate :parent_cannot_be_child

  before_save :normalize_name

  scope :roots, -> { where(parent_id: nil) }
  scope :sorted, -> { order(:name) }

  def self.find_or_create_by_name(name, parent: nil)
    find_or_create_by(name: name.strip.downcase.titleize, parent: parent)
  end

  def root?
    parent_id.nil?
  end

  def full_name
    parent ? "#{parent.name} > #{name}" : name
  end

  private

  def normalize_name
    self.name = name.strip.downcase.titleize
  end

  def parent_cannot_be_child
    return unless parent_id.present?

    if parent_id == id
      errors.add(:parent, "cannot be itself")
    elsif parent&.parent_id.present?
      errors.add(:parent, "cannot be a child genre (only 2 levels allowed)")
    end
  end
end
