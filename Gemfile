source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in activecube.gemspec
gemspec

group :development do
  gem 'rubocop', '~> 1.38'
  gem 'rubocop-performance', '~> 1.15'
end

group :test do
  gem 'clickhouse-activerecord', git: 'https://github.com/bitquery/clickhouse-activerecord.git'
end
