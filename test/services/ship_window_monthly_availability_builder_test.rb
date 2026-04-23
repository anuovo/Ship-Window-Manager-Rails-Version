require "test_helper"

class ShipWindowMonthlyAvailabilityBuilderTest < ActiveSupport::TestCase
  test "derives monthly availability segments from ship window ranges" do
    program = build_program
    item = build_item(program)
    range = program.ship_window_ranges.create!(
      start_date: Date.new(2025, 12, 28),
      end_date: Date.new(2026, 2, 15),
      item_ids: [item.id]
    )

    segments = ShipWindowMonthlyAvailabilityBuilder.new(program).call

    assert_equal 3, segments.length
    assert_equal(
      {
        month_key: "2025-12",
        label: "DECEMBER 2025",
        ship_window_range_id: range.id,
        display_start_date: "2025-12-28",
        display_end_date: "2025-12-31",
        item_ids: [item.id]
      },
      segments.first
    )
    assert_equal "2026-01", segments.second[:month_key]
    assert_equal "2026-01-01", segments.second[:display_start_date]
    assert_equal "2026-01-31", segments.second[:display_end_date]
    assert_equal "2026-02-15", segments.third[:display_end_date]
  end
end

