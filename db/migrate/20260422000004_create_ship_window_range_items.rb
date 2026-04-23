class CreateShipWindowRangeItems < ActiveRecord::Migration[6.1]
  def change
    create_table :ship_window_range_items do |t|
      t.references :ship_window_range, null: false, foreign_key: true, index: { name: "idx_range_items_on_range_id" }
      t.references :item, null: false, foreign_key: true

      t.timestamps
    end

    add_index :ship_window_range_items, [:ship_window_range_id, :item_id], unique: true, name: "idx_range_items_unique_range_item"
  end
end

