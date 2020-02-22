module Metric
  class Amount < Activecube::Metric

    include QueryHelper
    include Activecube::Common::Metrics

    column 'value'

    modifier :calculate

    def expression arel_table, measure, cube_query
      if calculate = measure.modifier(:calculate)
        self.send(calculate.args.first, arel_table, measure, cube_query) /  Arel.sql(dict_currency_divider('currency_id'))
      else
        sum(arel_table, measure, cube_query) /  Arel.sql(dict_currency_divider('currency_id'))
      end
    end

  end
end