module Dimension
  class DateField < Activecube::Field
    def format(string)
      @format = string
    end

    def expression(_model, _arel_table, _slice, _cube_query)
      "formatDateTime(tx_date,'#{@format || DEFAULT_FORMAT}')"
    end
  end
end
