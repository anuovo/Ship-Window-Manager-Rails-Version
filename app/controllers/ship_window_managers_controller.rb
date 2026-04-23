class ShipWindowManagersController < ApplicationController
  def show
    @program = Program.includes(:items, ship_window_ranges: :items).first || seed_program
    @ranges = @program.ship_window_ranges.order(:start_date, :id)
    ensure_default_range if @ranges.empty?
    @ranges = @program.ship_window_ranges.includes(:items).order(:start_date, :id)
    @monthly_grid = ShipWindowMonthlyGridBuilder.call(@program, ranges: @ranges)
  end

  def update
    @program = Program.includes(:items).first || seed_program
    result = save_ranges

    if result[:ok]
      redirect_to ship_window_manager_path, notice: "Ship windows saved."
    else
      @ranges = result[:ranges]
      @monthly_grid = ShipWindowMonthlyGridBuilder.call(@program, ranges: @ranges)
      flash.now[:alert] = result[:errors].join(", ")
      render :show, status: :unprocessable_entity
    end
  end

  private

  def save_ranges
    raw_ranges = JSON.parse(params[:ranges_json].presence || "[]")
    errors = validate_payload(raw_ranges)
    return { ok: false, ranges: preview_ranges(raw_ranges), errors: errors } if errors.any?

    ActiveRecord::Base.transaction do
      keep_ids = []

      raw_ranges.each do |raw|
        range = if raw["id"].present?
          @program.ship_window_ranges.find(raw["id"])
        else
          @program.ship_window_ranges.build
        end

        range.start_date = raw["start_date"]
        range.end_date = raw["end_date"]
        range.item_ids = raw["item_ids"].map(&:to_i)
        range.skip_overlap_validation = true
        range.save!
        keep_ids << range.id
      end

      @program.ship_window_ranges.where.not(id: keep_ids).destroy_all
    end

    { ok: true }
  rescue JSON::ParserError
    { ok: false, ranges: @program.ship_window_ranges.includes(:items).order(:start_date, :id), errors: ["Ship window data could not be read."] }
  rescue ActiveRecord::RecordInvalid => e
    { ok: false, ranges: @program.ship_window_ranges.includes(:items).order(:start_date, :id), errors: e.record.errors.full_messages }
  end

  def validate_payload(raw_ranges)
    errors = []
    item_ids = @program.items.pluck(:id)

    raw_ranges.each_with_index do |raw, index|
      label = "Ship Window #{index + 1}"
      start_date = parse_date(raw["start_date"])
      end_date = parse_date(raw["end_date"])
      selected_ids = Array(raw["item_ids"]).map(&:to_i)

      errors << "#{label}: start date is required" if start_date.blank?
      errors << "#{label}: end date is required" if end_date.blank?
      errors << "#{label}: end date cannot be earlier than start date" if start_date.present? && end_date.present? && end_date < start_date
      if start_date.present? && end_date.present? && (start_date < @program.ship_start_date || end_date > @program.ship_end_date)
        errors << "#{label}: range must stay within the program ship period"
      end
      errors << "#{label}: at least one item must be assigned" if selected_ids.empty?
      errors << "#{label}: includes an item outside this program" if (selected_ids - item_ids).any?
    end

    raw_ranges.each_with_index do |left, left_index|
      left_start = parse_date(left["start_date"])
      left_end = parse_date(left["end_date"])
      next if left_start.blank? || left_end.blank?

      raw_ranges.each_with_index do |right, right_index|
        next if right_index <= left_index

        right_start = parse_date(right["start_date"])
        right_end = parse_date(right["end_date"])
        next if right_start.blank? || right_end.blank?
        next unless left_start <= right_end && left_end >= right_start

        duplicate_item_ids = Array(left["item_ids"]).map(&:to_i) & Array(right["item_ids"]).map(&:to_i)
        if duplicate_item_ids.any?
          errors << "Ship Window #{left_index + 1} and Ship Window #{right_index + 1}: the same item cannot be assigned to overlapping ranges"
        end
      end
    end

    errors.uniq
  end

  def preview_ranges(raw_ranges)
    raw_ranges.map do |raw|
      range = @program.ship_window_ranges.build(
        id: raw["id"].presence,
        start_date: raw["start_date"],
        end_date: raw["end_date"]
      )
      range.items = @program.items.where(id: Array(raw["item_ids"]).map(&:to_i))
      range
    end
  end

  def parse_date(value)
    Date.iso8601(value.to_s)
  rescue ArgumentError
    nil
  end

  def ensure_default_range
    @program.ship_window_ranges.create!(
      start_date: @program.ship_start_date,
      end_date: @program.ship_end_date,
      item_ids: @program.items.pluck(:id)
    )
  end

  def seed_program
    Rails.application.load_seed
    Program.includes(:items).first
  end
end
