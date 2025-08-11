source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.2'

gem "rails", "~> 6.1.7", ">= 6.1.7.8"
gem "rack", "~> 2.2.8"

gem 'pg', '>= 0.18', '< 2.0'

gem 'puma', '~> 3.11'
gem 'uglifier', '>= 1.3.0'
gem 'jbuilder', '~> 2.5'
gem "bootsnap", "~> 1.18"
gem 'googleauth'
gem 'google-api-client'
gem 'dotenv-rails'
gem 'google_drive'

group :development, :test do
  gem 'pry'
  gem 'rspec-rails'
end

group :development do
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
end


# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:windows, :jruby]
