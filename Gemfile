source "https://rubygems.org"

gem "rails", "~> 8.0.1"
gem "propshaft"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "tzinfo-data", platforms: %i[windows jruby]
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false
gem "oj_serializers"
gem "redis", "~> 5.3"

group :development, :test do
  gem "rspec-rails"
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "factory_bot_rails", "~> 6.4"
end

group :development do
  gem "web-console"
end

group :test do
  gem "shoulda-matchers", "~> 6.4"
  gem "rswag-specs"
end

group :development, :test do
  gem "rswag-api"
  gem "rswag-ui"
end
