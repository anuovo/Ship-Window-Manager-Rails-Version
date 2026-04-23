# Ship Window Manager

A Ruby on Rails prototype for defining program ship window date ranges and assigning items to each range. Ship window ranges are the source of truth; monthly availability is derived read-only by `ShipWindowMonthlyAvailabilityBuilder`.

## Local Setup

This app targets Ruby 3.1.4 with Rails 6.1.x for deployment compatibility.

```bash
bundle config set --local without production
bundle install
bin/rails db:setup
bin/rails server
```

Open `http://localhost:3000`.

The production `pg` gem remains in the bundle for Postgres deployment. The local Bundler config above skips production gems so SQLite setup does not require PostgreSQL client headers.

The seed data creates a sample program with a ship period of `10/26/2025 - 10/31/2026`, seven ApplePear items, and a default Ship Window 1 covering the full program period with all items selected.

## Tests

```bash
bin/rails test
```

The tests cover ship window validation rules and monthly segment derivation.

## Deployment

Production is PostgreSQL-ready via `DATABASE_URL`. The simplest hosted path is Render.

### Render

For a free demo service without a database, omit `DATABASE_URL`. Production will use SQLite at `storage/production.sqlite3`. This is fine for stakeholder testing, but data is not durable like managed PostgreSQL.

Use these commands for a manual Render Web Service:

```bash
bundle config set without development test && bundle install && bundle exec rails db:migrate db:seed && bundle exec rails assets:precompile
bundle exec puma -C config/puma.rb
```

Set environment variables:

```bash
RAILS_ENV=production
RAILS_SERVE_STATIC_FILES=true
SECRET_KEY_BASE=<generated secret>
```

If using managed PostgreSQL, also add `DATABASE_URL=<render postgres internal url>`.

Generate `SECRET_KEY_BASE` locally with:

```bash
bundle exec rails secret
```

### Fly.io or Heroku

Both work as long as `DATABASE_URL`, `SECRET_KEY_BASE`, and `RAILS_ENV=production` are set. Run `rails db:migrate db:seed` during release/setup.

## Data Model

- `Program` has many `items` and `ship_window_ranges`
- `Item` belongs to `program`
- `ShipWindowRange` belongs to `program` and has many `items` through `ship_window_range_items`
- `ShipWindowRangeItem` joins ranges to items

## Monthly Availability

Use:

```ruby
ShipWindowMonthlyAvailabilityBuilder.new(program).call
```

It returns hashes with `month_key`, `label`, `ship_window_range_id`, `display_start_date`, `display_end_date`, and `item_ids`.
# Ship-Window-Manager-Rails-Version
