class Item < ApplicationRecord
  belongs_to :program
  has_many :ship_window_range_items, dependent: :destroy
  has_many :ship_window_ranges, through: :ship_window_range_items

  validates :class_name, :item_code, :description, presence: true
  validates :item_code, uniqueness: { scope: :program_id }
end

