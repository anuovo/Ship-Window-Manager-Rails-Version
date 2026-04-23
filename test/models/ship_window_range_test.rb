require "test_helper"

class ShipWindowRangeTest < ActiveSupport::TestCase
  test "requires start and end dates" do
    program = build_program
    item = build_item(program)
    range = program.ship_window_ranges.new(item_ids: [item.id])

    assert_not range.valid?
    assert_includes range.errors[:start_date], "can't be blank"
    assert_includes range.errors[:end_date], "can't be blank"
  end

  test "end date cannot be earlier than start date" do
    program = build_program
    item = build_item(program)
    range = program.ship_window_ranges.new(start_date: Date.new(2026, 2, 1), end_date: Date.new(2026, 1, 1), item_ids: [item.id])

    assert_not range.valid?
    assert_includes range.errors[:end_date], "cannot be earlier than start date"
  end

  test "range must stay within program ship period" do
    program = build_program
    item = build_item(program)
    range = program.ship_window_ranges.new(start_date: Date.new(2025, 10, 1), end_date: Date.new(2026, 1, 1), item_ids: [item.id])

    assert_not range.valid?
    assert_includes range.errors[:base], "range must stay within the program ship period"
  end

  test "requires at least one assigned item" do
    program = build_program
    range = program.ship_window_ranges.new(start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 31))

    assert_not range.valid?
    assert_includes range.errors[:base], "at least one item must be assigned"
  end

  test "prevents same item on overlapping ranges" do
    program = build_program
    item = build_item(program)
    program.ship_window_ranges.create!(start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 31), item_ids: [item.id])

    range = program.ship_window_ranges.new(start_date: Date.new(2026, 1, 15), end_date: Date.new(2026, 2, 15), item_ids: [item.id])

    assert_not range.valid?
    assert_includes range.errors[:base], "the same item cannot be assigned to multiple overlapping ranges"
  end

  test "allows same item on non-overlapping ranges" do
    program = build_program
    item = build_item(program)
    program.ship_window_ranges.create!(start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 31), item_ids: [item.id])

    range = program.ship_window_ranges.new(start_date: Date.new(2026, 2, 1), end_date: Date.new(2026, 2, 15), item_ids: [item.id])

    assert range.valid?
  end
end

