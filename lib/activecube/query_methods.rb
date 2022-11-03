require 'activecube/query/cube_query'

module Activecube
  module QueryMethods
    attr_reader :database, :role

    %i[slice measure when desc desc_by_integer asc asc_by_integer limit offset].each do |method|
      define_method(method) do |*args|
        Query::CubeQuery.new(self).send method, *args
      end
    end

    def connected_to(database: nil, role: nil, &block)
      raise Activecube::InputArgumentError, 'Must pass block to method' unless block

      super_model.connected_to(database: database, role: role) do
        @database = database
        @role = role
        yield self
      end
    end

    private

     def super_model
      raise Activecube::InputArgumentError, "No tables specified for cube #{name}" unless models && models.count > 0

      models.collect do |m|
        m < View ? m.models : m
      end.flatten.uniq.collect do |t|
        t.ancestors.select { |c| c < ActiveRecord::Base }
      end.transpose.select do |c|
        c.uniq.count == 1
      end.last.first
    end
  end
end
