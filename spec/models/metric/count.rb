module Metric
  class Count < Activecube::Metric
    include Activecube::Common::Metrics

    def expression(model, arel_table, measure, cube_query)
      count(model, arel_table, measure, cube_query)
    end
  end
end
