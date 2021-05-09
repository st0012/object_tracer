source "https://rubygems.org"

# Specify your gem's dependencies in tapping_device.gemspec
gemspec

rails_version = ENV["RAILS_VERSION"]
rails_version = "6.1.0" if rails_version.nil?

if rails_version.to_f < 6
  gem "sqlite3", "~> 1.3.0"
else
  gem "sqlite3"
end

gem "activerecord", "~> #{rails_version}"
gem "pry"
