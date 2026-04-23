ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  def build_program
    Program.create!(
      name: "Test Program",
      ship_start_date: Date.new(2025, 10, 26),
      ship_end_date: Date.new(2026, 10, 31)
    )
  end

  def build_item(program, code = "41021")
    program.items.create!(
      class_name: "ApplePear",
      item_code: code,
      description: "Apples, Red Del, WA Xcy, 100ct"
    )
  end
end
