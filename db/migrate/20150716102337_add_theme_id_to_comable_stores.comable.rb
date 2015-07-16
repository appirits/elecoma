# This migration comes from comable (originally 20150612143445)
class AddThemeIdToComableStores < ActiveRecord::Migration
  def change
    change_table :comable_stores do |t|
      t.references :theme
    end
  end
end
