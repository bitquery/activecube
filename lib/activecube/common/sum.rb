module Activecube::Common

  class Sum < Activecube::Metric

    def expression arel_table, measure, cube_query
      column = arel_table[self.class.column_name.to_sym]
      measure.selectors.empty? ? column.sum : column.sumIf(measure.condition_query arel_table, cube_query)
    end

  end
end