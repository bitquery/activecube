require 'activecube/definition_methods'

module Activecube
  class Selector
    extend DefinitionMethods

    def expression(model, arel_table, selector, _cube_query)
      op = selector.operator
      op.expression model, arel_table[self.class.column_name.to_sym], op.argument
    end
  end
end
