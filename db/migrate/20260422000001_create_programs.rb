class CreatePrograms < ActiveRecord::Migration[6.1]
  def change
    create_table :programs do |t|
      t.string :name, null: false
      t.date :ship_start_date, null: false
      t.date :ship_end_date, null: false

      t.timestamps
    end
  end
end

