module Dimension
  class Date < Activecube::Dimension
    DEFAULT_FORMAT = '%Y-%m-%d'

    column 'tx_date'

    field 'month', 'toMonth(tx_date)'
    field 'year', 'toYear(tx_date)'
    field 'dayOfMonth', 'toDayOfMonth(tx_date)'
    field 'dayOfWeek', 'toDayOfWeek(tx_date)'

    field 'date', DateField

    field 'date_inline', (Class.new(Activecube::Field) do
      def format(string)
        @format = string
      end

      def expression(_model, _arel_table, _slice, _cube_query)
        "formatDateTime(tx_date,'#{@format || DEFAULT_FORMAT}')"
      end
    end)

    field 'day', {
      year: {
        number: 'toYear(tx_date)'
      },
      date: {
        formatted: (Class.new(Activecube::Field) do
          def format(string)
            @format = string
          end

          def expression(_model, _arel_table, _slice, _cube_query)
            "formatDateTime(tx_date,'#{@format || DEFAULT_FORMAT}')"
          end
        end)
      }
    }
  end
end
