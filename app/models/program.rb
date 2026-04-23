class Program < ApplicationRecord
  has_many :items, dependent: :destroy
  has_many :ship_window_ranges, dependent: :destroy

  validates :name, :ship_start_date, :ship_end_date, presence: true
  validate :ship_end_date_not_before_start

  private

  def ship_end_date_not_before_start
    return if ship_start_date.blank? || ship_end_date.blank?

    errors.add(:ship_end_date, "cannot be earlier than ship start date") if ship_end_date < ship_start_date
  end
end

