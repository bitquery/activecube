require 'activecube/modifier'
require 'activecube/query/modification'

module Activecube::Query
  class Measure < Item
    attr_reader :selectors, :modifications

    def initialize cube, key, definition, selectors = [], modifications = []
      super cube, key, definition
      @selectors = selectors
      @modifications = modifications

      modifier_methods! if definition.class.modifiers
    end

    def required_column_names
      ((definition.class.column_names || []) + selectors.map(&:required_column_names)).flatten.uniq
    end

    def when *args
      append *args, @selectors, Selector, cube.selectors
    end

    def alias! new_key
      self.class.new cube, new_key, definition, selectors, modifications
    end

    def condition_query arel_table, cube_query
      condition = nil
      selectors.each do |selector|
        condition = condition ?
                        condition.and(selector.expression(arel_table, cube_query)) :
                        selector.expression(arel_table, cube_query)
      end
      condition
    end

    def append_query cube_query, table, query
      attr_alias = "`#{key.to_s}`"
      expr = definition.expression table, self, cube_query
      query.project expr.as(attr_alias)
    end

    def to_s
      "Metric #{super}"
    end

    def modifier name
      ms = modifications.select{|m| m.modifier.name==name}
      raise "Found multiple (#{ms.count}) definitions for #{name} in #{self}" if ms.count>1
      ms.first
    end

    private

    def modifier_methods!
      definition.class.modifiers.each_pair do |key, modifier|
        define_singleton_method key do |*args|
          (@modifications ||= []) << Modification.new(modifier, *args)
          self
        end
      end
    end
  end
end