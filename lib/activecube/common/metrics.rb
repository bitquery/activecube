module Activecube::Common
  module Metrics
    METHODS = %i[count minimum maximum average sum uniqueExact unique median medianExact any anyLast]

    METHODS.each do |fname|
      if fname == :count
        define_method fname do |model, arel_table, measure, cube_query|
          if measure.selectors.empty?
            Arel.star.count
          else
            Arel.star.countIf(measure.condition_query(model, arel_table,
                                                      cube_query))
          end
        end
      else
        define_method fname do |model, arel_table, measure, cube_query|
          column = pre_aggregate_value model, arel_table, measure, cube_query
          if measure.selectors.empty?
            column.send(fname)
          else
            column.send(fname.to_s + 'If',
                        measure.condition_query(model, arel_table,
                                                cube_query))
          end
        end
      end
    end

    def pre_aggregate_value(_model, arel_table, _measure, _cube_query)
      arel_table[self.class.column_name.to_sym]
    end
  end
end
