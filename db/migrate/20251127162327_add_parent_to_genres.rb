class AddParentToGenres < ActiveRecord::Migration[8.1]
  def change
    add_reference :genres, :parent, null: true, foreign_key: { to_table: :genres }
  end
end
