class AddStatusToBooks < ActiveRecord::Migration[8.1]
  def change
    add_column :books, :status, :string, default: "in", null: false
    add_column :books, :borrower_name, :string
  end
end
