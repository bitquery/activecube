module Metric
  class Count < Activecube::Metric

    include Activecube::Common::Metrics

    def expression arel_table, measure, cube_query
      count(arel_table, measure, cube_query)
    end

  end
end