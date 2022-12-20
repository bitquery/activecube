require 'active_support/concern'

module Activecube::ViewDefinition
  attr_reader :activecube_indexes, :models, :any_column_tables

  def index(index_name, *args)
    (@activecube_indexes ||= []) << Activecube::Processor::Index.new(index_name, *args)
  end

  def table(x)
    (@models ||= []) << x
  end

  def any(column_name, table)
    (@any_column_tables ||= []) << {column: column_name, table: table}
    self.table table
  end

end
