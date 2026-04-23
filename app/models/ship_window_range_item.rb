class ShipWindowRangeItem < ApplicationRecord
  belongs_to :ship_window_range
  belongs_to :item

  validates :item_id, uniqueness: { scope: :ship_window_range_id }
end

