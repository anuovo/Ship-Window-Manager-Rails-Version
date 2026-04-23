class ShipWindowRange < ApplicationRecord
  attr_accessor :skip_overlap_validation

  belongs_to :program
  has_many :ship_window_range_items, dependent: :destroy
  has_many :items, through: :ship_window_range_items

  validates :start_date, :end_date, presence: true
  validate :end_date_not_before_start
  validate :within_program_ship_period
  validate :has_at_least_one_item
  validate :items_do_not_overlap_other_ranges

  private

  def end_date_not_before_start
    return if start_date.blank? || end_date.blank?

    errors.add(:end_date, "cannot be earlier than start date") if end_date < start_date
  end

  def within_program_ship_period
    return if program.blank? || start_date.blank? || end_date.blank?

    if start_date < program.ship_start_date || end_date > program.ship_end_date
      errors.add(:base, "range must stay within the program ship period")
    end
  end

  def has_at_least_one_item
    ids = item_ids.reject(&:blank?)
    errors.add(:base, "at least one item must be assigned") if ids.empty?
  end

  def items_do_not_overlap_other_ranges
    return if skip_overlap_validation
    return if program.blank? || start_date.blank? || end_date.blank?

    ids = item_ids.reject(&:blank?)
    return if ids.empty?

    overlapping_ranges = program.ship_window_ranges
      .where.not(id: id)
      .where("start_date <= ? AND end_date >= ?", end_date, start_date)
      .joins(:ship_window_range_items)
      .where(ship_window_range_items: { item_id: ids })
      .distinct

    return unless overlapping_ranges.exists?

    errors.add(:base, "the same item cannot be assigned to multiple overlapping ranges")
  end
end
