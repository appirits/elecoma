# This migration comes from comable (originally 20150519080729)
class CreateComablePages < ActiveRecord::Migration
  def change
    create_table :comable_pages do |t|
      t.string :title, null: false
      t.text :content, null: false
      t.string :page_title
      t.string :meta_description
      t.string :meta_keywords
      t.string :slug, null: false
      t.datetime :published_at

      t.timestamps null: false
    end

    add_index :comable_pages, :slug, unique: true
  end
end
