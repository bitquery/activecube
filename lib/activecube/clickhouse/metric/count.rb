module Activecube::Clickhouse::Metric

  class Count < Activecube::Metric

    def expression arel_table, measure, cube_query
      measure.selectors.empty? ? Arel.star.count : Arel.star.countIf(measure.condition_query arel_table, cube_query)
    end

  end
end