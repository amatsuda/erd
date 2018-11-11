class CreateBooks < ActiveRecord::VERSION::MAJOR >= 5 ? ActiveRecord::Migration[5.0] : ActiveRecord::Migration
  def change
    create_table :books do |t|
      t.references :author
      t.string :title

      t.timestamps
    end
  end
end
