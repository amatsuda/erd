class CreateBooks < ActiveRecord::Migration
  def change
    create_table :books do |t|
      t.references :author
      t.string :title

      t.timestamps
    end
    add_index :books, :author_id
  end
end
