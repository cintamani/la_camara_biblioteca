class ChangeIsbnToIsbnsInBooks < ActiveRecord::Migration[8.1]
  def up
    # Remove the unique index on isbn
    remove_index :books, :isbn

    # Rename isbn to isbns
    rename_column :books, :isbn, :isbns

    # Convert existing single ISBN values to JSON arrays
    Book.reset_column_information
    Book.find_each do |book|
      if book.isbns.present?
        # Store as JSON array
        book.update_column(:isbns, [ book.isbns ].to_json)
      else
        book.update_column(:isbns, "[]")
      end
    end
  end

  def down
    # Convert JSON arrays back to single ISBN
    Book.reset_column_information
    Book.find_each do |book|
      if book.isbns.present?
        isbns = JSON.parse(book.isbns) rescue []
        book.update_column(:isbns, isbns.first)
      end
    end

    rename_column :books, :isbns, :isbn
    add_index :books, :isbn, unique: true
  end
end
