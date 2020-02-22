module Activecube::Query
  class Measure < Item

    attr_reader :selectors

    def initialize cube, key, definition, selectors = []
      super cube, key, definition
      @selectors = selectors
    end

    def required_column_names
      ((definition.class.column_names || []) + selectors.map(&:required_column_names)).flatten.uniq
    end

    def when *args
      append *args, @selectors, Selector, cube.selectors
    end

    def alias! new_key
      self.class.new cube, new_key, definition, selectors
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

  end
end