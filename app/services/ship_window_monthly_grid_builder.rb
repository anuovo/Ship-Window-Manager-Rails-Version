class ShipWindowMonthlyGridBuilder
  def self.call(program, ranges: nil)
    new(program, ranges: ranges).call
  end

  def initialize(program, ranges: nil)
    @program = program
    @ranges = Array(ranges || program.ship_window_ranges.includes(:items).order(:start_date, :id))
  end

  def call
    {
      months: month_headers,
      groups: grouped_windows.map.with_index(1) { |windows, index| build_group(windows, index) }
    }
  end

  private

  attr_reader :program, :ranges

  def month_headers
    cursor = program.ship_start_date.beginning_of_month
    final_month = program.ship_end_date.beginning_of_month
    months = []

    while cursor <= final_month
      months << { key: month_key(cursor), label: cursor.strftime("%b %y") }
      cursor = cursor.next_month
    end

    months
  end

  def grouped_windows
    groups = []

    eligible_ranges.each do |range|
      if groups.any? && consecutive_with_shared_items?(groups.last.last, range)
        groups.last << range
      else
        groups << [range]
      end
    end

    groups
  end

  def eligible_ranges
    ranges.select do |range|
      range.start_date.present? && range.end_date.present? && range.end_date >= range.start_date && range.item_ids.any?
    end.sort_by { |range| [range.start_date, range.end_date, range.id || 0] }
  end

  def consecutive_with_shared_items?(previous, current)
    previous.end_date + 1.day == current.start_date && (previous.item_ids & current.item_ids).any?
  end

  def build_group(windows, index)
    {
      group_id: "group-#{index}",
      windows: windows.map { |window| build_window(window) },
      items: items_for(windows)
    }
  end

  def build_window(window)
    {
      id: window.id,
      label: label_for(window),
      start_date: window.start_date.to_s,
      end_date: window.end_date.to_s,
      item_ids: window.item_ids.sort,
      segments_by_month: segments_by_month_for(window)
    }
  end

  def label_for(window)
    sorted = eligible_ranges
    "Ship Window #{sorted.index(window).to_i + 1}"
  end

  def segments_by_month_for(window)
    start_month = display_start_month_for(window)
    final_month = window.end_date.beginning_of_month
    segments = {}
    cursor = start_month

    while cursor <= final_month
      display_start = cursor == start_month ? window.start_date : [window.start_date, cursor].max
      display_end = [window.end_date, cursor.end_of_month].min

      segments[month_key(cursor)] = {
        display_start_date: display_start.to_s,
        display_end_date: display_end.to_s
      }

      cursor = cursor.next_month
    end

    segments
  end

  def display_start_month_for(window)
    if starts_immediately_after_another_window?(window) && window.start_date.day > 1
      next_month = window.start_date.next_month.beginning_of_month
      return next_month if next_month <= window.end_date.beginning_of_month
    end

    window.start_date.beginning_of_month
  end

  def starts_immediately_after_another_window?(window)
    eligible_ranges.any? { |candidate| candidate != window && candidate.end_date + 1.day == window.start_date }
  end

  def items_for(windows)
    item_ids = windows.flat_map(&:item_ids).uniq
    program.items.where(id: item_ids).order(:item_code).map do |item|
      {
        id: item.id,
        item_code: item.item_code,
        description: item.description,
        segments_by_month: item_segments_by_month(item.id, windows)
      }
    end
  end

  def item_segments_by_month(item_id, windows)
    segments = {}

    windows.each do |window|
      next unless window.item_ids.include?(item_id)

      segments_by_month_for(window).each do |key, segment|
        segments[key] ||= []
        segments[key] << segment.merge(ship_window_range_id: window.id, label: label_for(window))
      end
    end

    segments
  end

  def month_key(date)
    date.strftime("%Y-%m")
  end
end
