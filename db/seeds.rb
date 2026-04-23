program = Program.find_or_create_by!(name: "Sample Produce Program") do |record|
  record.ship_start_date = Date.new(2025, 10, 26)
  record.ship_end_date = Date.new(2026, 10, 31)
end

program.update!(
  ship_start_date: Date.new(2025, 10, 26),
  ship_end_date: Date.new(2026, 10, 31)
)

items = [
  ["ApplePear", "41021", "Apples, Red Del, WA Xcy, 100ct"],
  ["ApplePear", "41022", "Apples, Red Del, WA Xcy, 113ct"],
  ["ApplePear", "41023", "Apple, Red Del, WA Xcy, 125ct"],
  ["ApplePear", "41024", "Apples, Red Del, WA Xcy, 138ct"],
  ["ApplePear", "41549", "Apples, Red Del, US Xcy, 163ct"],
  ["ApplePear", "41101", "Apples, Gold Del, US Xcy, 88ct"],
  ["ApplePear", "41102", "Apples, Gold Del, US Xcy, 100ct"]
]

items.each do |class_name, item_code, description|
  item = program.items.find_or_initialize_by(item_code: item_code)
  item.update!(class_name: class_name, description: description)
end

if program.ship_window_ranges.empty?
  program.ship_window_ranges.create!(
    start_date: program.ship_start_date,
    end_date: program.ship_end_date,
    item_ids: program.items.pluck(:id)
  )
end

