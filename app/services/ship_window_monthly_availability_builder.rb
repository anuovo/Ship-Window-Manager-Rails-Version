class ShipWindowMonthlyAvailabilityBuilder
  def initialize(program)
    @program = program
  end

  def call
    program.ship_window_ranges.includes(:items).order(:start_date, :id).flat_map do |range|
      monthly_segments_for(range)
    end
  end

  private

  attr_reader :program

  def monthly_segments_for(range)
    cursor = range.start_date.beginning_of_month
    final_month = range.end_date.beginning_of_month
    segments = []

    while cursor <= final_month
      display_start = [range.start_date, cursor].max
      display_end = [range.end_date, cursor.end_of_month].min

      segments << {
        month_key: cursor.strftime("%Y-%m"),
        label: cursor.strftime("%B %Y").upcase,
        ship_window_range_id: range.id,
        display_start_date: display_start.to_s,
        display_end_date: display_end.to_s,
        item_ids: range.item_ids.sort
      }

      cursor = cursor.next_month
    end

    segments
  end
end

