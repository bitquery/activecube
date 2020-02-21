require 'activecube/query/cube_query'

module Activecube
  module QueryMethods

    attr_reader :database, :role

    [:slice, :measure, :when, :skip, :take, :desc, :asc].each do |method|
      define_method(method) do |*args|
        Query::CubeQuery.new(self).send method, *args
      end
    end

    def connected_to database: nil, role: nil, &block
      raise ArgumentError, "Must pass block to method" unless block_given?
      super_model.connected_to(database: database, role: role) do
        @database = database
        @role = role
        block.call self
      end
    end

    private


    def super_model
      raise ArgumentError, "No tables specified for cube #{name}" if tables.count==0
      return tables.first.model if tables.count==1

      tables.collect{ |t|
        t.model.ancestors.select{|c| c <= ActiveRecord::Base }.reverse
      }.transpose.select{|c|
        c.uniq.count==1
      }.last.first

    end


  end
end
