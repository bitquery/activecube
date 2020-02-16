# Activecube: Multi-Dimensional Queries with Rails

Activecube is the library to make multi-dimensional queries to data warehouse, such as:

```sql

Cube.slice(
    date: cube.dimensions[:date][:date].format('%Y-%m'),
    currency: cube.dimensions[:currency][:symbol]
).measure(:count).
when(cube.selectors[:currency].in('USD','EUR').to_sql
```

Cube, dimensions, metrics and selectors are defined in the Model, similary to
ActiveRecord.

Activecube uses Rails ActiveRecord in implementation. 

In particular, you have to define all tables, used in
Activecube, as ActiveRecord tables.

 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activecube'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install activecube

## Usage

TBD

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bitquery/activecube. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Activecube project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/bitquery/activecube/blob/master/CODE_OF_CONDUCT.md).
