class CreateShipWindowRanges < ActiveRecord::Migration[6.1]
  def change
    create_table :ship_window_ranges do |t|
      t.references :program, null: false, foreign_key: true
      t.date :start_date, null: false
      t.date :end_date, null: false

      t.timestamps
    end
  end
end

