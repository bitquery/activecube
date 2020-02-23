require "bundler/setup"
require "activecube"

require 'models/application_record'
require 'models/query_helper'

require 'models/test/transfers_currency'
require 'models/test/transfers_from'
require 'models/test/transfers_to'

require 'models/test/currency_selector'
require 'models/test/transfer_from_selector'
require 'models/test/transfer_to_selector'
require 'models/test/date_selector'

require 'models/dimension/currency'
require 'models/dimension/date_field'
require 'models/dimension/date'


require 'models/metric/amount'
require 'models/metric/count'

require 'models/test/transfers_cube'


MIGRATIONS_PATH = File.join(File.dirname(__FILE__), 'migrations')

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end


  ActiveRecord::Base.configurations = HashWithIndifferentAccess.new(
      default: {
          adapter: 'clickhouse',
          host: 'clickhouse',
          port: 8123,
          database: 'test',
          username: nil,
          password: nil
      }
  )

  ActiveRecord::Base.establish_connection(:default)

end


