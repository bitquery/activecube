module Activecube
  class Selector
    extend DimensionDefinitionMethods

    def expression arel_table, selector, _cube_query
      op = selector.operator
      op.expression arel_table[self.class.column_name.to_sym], op.argument
    end

  end
end