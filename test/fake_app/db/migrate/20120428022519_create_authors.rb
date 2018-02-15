class CreateAuthors < ActiveRecord::VERSION::MAJOR >= 5 ? ActiveRecord::Migration[4.2] : ActiveRecord::Migration
  def change
    create_table :authors do |t|
      t.string :name

      t.timestamps
    end
  end
end
