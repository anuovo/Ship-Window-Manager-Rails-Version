require "test_helper"

class ShipWindowMonthlyGridBuilderTest < ActiveSupport::TestCase
  test "builds month headers across the program ship period" do
    program = build_program
    build_item(program)

    grid = ShipWindowMonthlyGridBuilder.call(program)

    assert_equal "2025-10", grid[:months].first[:key]
    assert_equal "Oct 25", grid[:months].first[:label]
    assert_equal "2026-10", grid[:months].last[:key]
    assert_equal "Oct 26", grid[:months].last[:label]
  end

  test "groups consecutive windows with shared item membership" do
    program = build_program
    first_item = build_item(program, "41021")
    second_item = build_item(program, "41022")
    third_item = build_item(program, "41023")

    program.ship_window_ranges.create!(start_date: Date.new(2025, 10, 26), end_date: Date.new(2025, 12, 27), item_ids: [first_item.id, second_item.id])
    program.ship_window_ranges.create!(start_date: Date.new(2025, 12, 28), end_date: Date.new(2026, 3, 28), item_ids: [second_item.id, third_item.id])
    program.ship_window_ranges.create!(start_date: Date.new(2026, 3, 29), end_date: Date.new(2026, 6, 27), item_ids: [third_item.id])

    grid = ShipWindowMonthlyGridBuilder.call(program)

    assert_equal 1, grid[:groups].length
    assert_equal 3, grid[:groups].first[:windows].length
    assert_equal [first_item.id, second_item.id], grid[:groups].first[:windows].first[:item_ids]
  end

  test "does not group consecutive windows without shared item membership" do
    program = build_program
    first_item = build_item(program, "41021")
    second_item = build_item(program, "41022")

    program.ship_window_ranges.create!(start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 31), item_ids: [first_item.id])
    program.ship_window_ranges.create!(start_date: Date.new(2026, 2, 1), end_date: Date.new(2026, 2, 28), item_ids: [second_item.id])

    grid = ShipWindowMonthlyGridBuilder.call(program)

    assert_equal 2, grid[:groups].length
    assert_equal [first_item.id], grid[:groups].first[:windows].first[:item_ids]
    assert_equal [second_item.id], grid[:groups].second[:windows].first[:item_ids]
  end

  test "moves contiguous late-month starts into the next month column" do
    program = build_program
    item = build_item(program)

    program.ship_window_ranges.create!(start_date: Date.new(2025, 10, 26), end_date: Date.new(2025, 12, 27), item_ids: [item.id])
    second = program.ship_window_ranges.create!(start_date: Date.new(2025, 12, 28), end_date: Date.new(2026, 3, 28), item_ids: [item.id])
    third = program.ship_window_ranges.create!(start_date: Date.new(2026, 3, 29), end_date: Date.new(2026, 6, 27), item_ids: [item.id])

    windows = ShipWindowMonthlyGridBuilder.call(program)[:groups].first[:windows]
    second_window = windows.detect { |window| window[:id] == second.id }
    third_window = windows.detect { |window| window[:id] == third.id }

    assert_nil second_window[:segments_by_month]["2025-12"]
    assert_equal "2025-12-28", second_window[:segments_by_month]["2026-01"][:display_start_date]
    assert_equal "2026-01-31", second_window[:segments_by_month]["2026-01"][:display_end_date]

    assert_nil third_window[:segments_by_month]["2026-03"]
    assert_equal "2026-03-29", third_window[:segments_by_month]["2026-04"][:display_start_date]
    assert_equal "2026-04-30", third_window[:segments_by_month]["2026-04"][:display_end_date]
  end

  test "item cells only include months from windows assigned to that item" do
    program = build_program
    first_item = build_item(program, "41021")
    second_item = build_item(program, "41022")

    program.ship_window_ranges.create!(start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 31), item_ids: [first_item.id])
    program.ship_window_ranges.create!(start_date: Date.new(2026, 2, 1), end_date: Date.new(2026, 2, 28), item_ids: [second_item.id])

    groups = ShipWindowMonthlyGridBuilder.call(program)[:groups]
    first_item_row = groups.flat_map { |group| group[:items] }.detect { |item| item[:id] == first_item.id }
    second_item_row = groups.flat_map { |group| group[:items] }.detect { |item| item[:id] == second_item.id }

    assert first_item_row[:segments_by_month]["2026-01"].present?
    assert_nil first_item_row[:segments_by_month]["2026-02"]
    assert second_item_row[:segments_by_month]["2026-02"].present?
    assert_nil second_item_row[:segments_by_month]["2026-01"]
  end
end
