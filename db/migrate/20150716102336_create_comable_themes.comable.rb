# This migration comes from comable (originally 20150612143226)
class CreateComableThemes < ActiveRecord::Migration
  def change
    create_table :comable_themes do |t|
      t.string :name, null: false
      t.string :version, null: false
      t.string :display
      t.string :description
      t.string :homepage
      t.string :author
      t.timestamps null: false
    end

    add_index :comable_themes, [:name, :version], unique: true
  end
end
