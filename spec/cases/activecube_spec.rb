RSpec.describe Activecube do


  before(:all) {
    ActiveRecord::MigrationContext.new(MIGRATIONS_PATH, ActiveRecord::Base.connection.schema_migration).up
  }

  it "does something useful" do

    puts Test::TransfersFrom.attribute_types
    expect(true).to eq(true)
  end
end
