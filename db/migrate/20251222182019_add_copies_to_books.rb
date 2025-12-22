class AddCopiesToBooks < ActiveRecord::Migration[8.1]
  def change
    add_column :books, :copies, :integer, default: 1, null: false
  end
end
