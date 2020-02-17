module Metric
  class Amount < Activecube::Common::Sum

    include QueryHelper

    column 'value'

    def expression arel_table, measure, cube_query
      selected_currency = cube_query.selectors.detect{|s| s.definition.kind_of?(Test::CurrencySelector) &&
          s.operator.operation=='eq' } || measure.selectors.detect{|s| s.definition.kind_of?(Test::CurrencySelector) &&
          s.operator.operation=='eq' }

        super(arel_table, measure, cube_query) /  Arel.sql(dict_currency_divider(
                                                               selected_currency.try(:operator).try(:argument) ||
                                                               'currency_id'))

    end

  end
end