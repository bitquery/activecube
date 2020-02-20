# Activecube: Multi-Dimensional Queries with Rails

Activecube is the library to make multi-dimensional queries to data warehouse, such as:

```ruby
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

Basic steps to use ActiveCube are:

1. Define your database schema in models, as you do with Rails
2. Setup connection properties to data warehouse in config/database.yml. You can use multiple connections 
if you use Rails 6 or higher
3. Define cubes in models, sub-classed from Activecube::Base. Look 
[spec/models/test/transfers_cube.rb](spec/models/test/transfers_cube.rb) as example
4. Make queries to the cubes

Check [spec/cases/activecube_spec.rb](spec/cases/activecube_spec.rb) for more examples.


### Cube definition 

Cube defined using the following attributes:

- **table** specifies, which physical database tables can be considered to query
```ruby
    table TransfersCurrency
    table TransfersFrom
    table TransfersTo
```

- **dimension** specifies classes used for slicing the cube

```ruby
    dimension date: Dimension::Date,
              currency: Dimension::Currency
```

Or 

```ruby
    dimension date: Dimension::Date
    dimension currency: Dimension::Currency
```

- **metric** specifies which results expected from the cube queries

```ruby
    metric amount: Metric::Amount,
           count: Metric::Count
```

Or

```ruby
    metric amount: Metric::Amount
    metric count: Metric::Count
```

- **selector** is a set of expressions, which can filter results

```ruby
    selector currency: CurrencySelector,
             transfer_from: TransferFromSelector,
             transfer_to: TransferToSelector
```

### Table definition

Tables are defined as regular active records, with additional optional attribute 'index':
```ruby
index 'currency_id', cardinality: 4
```

which means that the table has an index onm currency_id field, with average number of different entries
of 10,000 ( 10^4). This creates a hint for optimizer to build queries.

Indexes can span multiple fields, as

```ruby
index ['currency_id','date'], cardinality: 6
```

Note, that if you created combined index in database, you most probable will need to define all
indexed combinations, for example:

```ruby
index ['currency_id'], cardinality: 4
index ['currency_id','date'], cardinality: 6
```

### Query language

You use the cube class to create and execute queries.

Queries can be expressed as Arel query, SQL or executed against the database, returning results.

The methods used to contruct the query:

- **slice** defines which dimensions slices the results
- **measure** defines what to measure
- **when** defines which selectors to apply
- **desc, asc, take, skip** are for ordering and limiting result set

(take and skip have aliases: offset and limit).

After the query contructed, the following methods can be applied:

- **to_sql** to generate String SQL query from cube query
- **to_query** to generate Arel query
- **query** to execute query and return ResultSet

### Managing Connections


You can control the connection used to construct and execute query by 
ActiveRecord standard API:

```ruby
ApplicationRecord.connected_to(database: :data_warehouse) do
      cube = My::TransfersCube
      cube.slice(
              date: cube.dimensions[:date][:date].format('%Y-%m'),
              currency: cube.dimensions[:currency][:symbol]
      ).measure(:count).query
    end
```

will query using data_warehouse configuraton.


Alternatively you can use the method provided by activecube. It will 
make the connection for the model or abstract class, which is super class for your models:

```ruby
My::TransfersCube.connected_to(database: :data_warehouse) do |cube|
      cube.slice(
              date: cube.dimensions[:date][:date].format('%Y-%m'),
              currency: cube.dimensions[:currency][:symbol]
      ).measure(:count).query
    end
```

## How it works

When you construct and execute cube query with any outcome ( sql, Arel query or ResultSet),
the same sequence of operations happen:

1) Cube is collecting the query into a set of objects from the chain method call;
2) Query is matched against the physical tables, the tables are selected that can serve the query or its part. For example, one table can provide one set of metrics, and the other can provide remaining;
3) If possible, the variant is selected from all possible options, which uses indexes with the most cardinality
4) Query is constructed using Arel SQL engine ( included in ActiveRecord ) using selected tables, and possibly joins
5) If requested, the query is converted to sql ( using Arel visitor ) or executed with database connection

## Optimization

The optimization on step #3 try to minimize the total cost of execution:

![Formula min max](https://latex.codecogs.com/png.latex?min(\sum_{tables}max_{metrics}(cost))))

where 

![Formula cost](https://latex.codecogs.com/png.latex?\inline&space;cost(metric,table)&space;=&space;1&space;/&space;(1&space;&plus;&space;cardinality(metric,&space;table)))

Optimization is done using the algorithm, which checks possible combinations of metrics and tables.


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## RSPec tests


To run tests, you need clickhouse server installation.
Tests use database 'test' that have to be created in clickhouse as:
```sql
CREATE DATABASE test;
```
Check credentials for connection in [spec/spec_helper.rb](spec/spec_helper.rb) file.
By default clickhouse must reside on "clickhouse" server name, port 8123 with the default user access open.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bitquery/activecube. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Activecube project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/bitquery/activecube/blob/master/CODE_OF_CONDUCT.md).
