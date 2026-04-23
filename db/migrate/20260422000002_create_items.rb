class CreateItems < ActiveRecord::Migration[6.1]
  def change
    create_table :items do |t|
      t.references :program, null: false, foreign_key: true
      t.string :class_name, null: false
      t.string :item_code, null: false
      t.string :description, null: false

      t.timestamps
    end

    add_index :items, [:program_id, :item_code], unique: true
  end
end

