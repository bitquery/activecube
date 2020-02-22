module Activecube::Common

  module Metrics

    METHODS = [:count, :minimum,:maximum,:average,:sum,:uniqueExact,:unique,:median,:any,:anyLast]

    METHODS.each do |fname|

      if fname==:count
        define_method fname do |model, arel_table, measure, cube_query|
          measure.selectors.empty? ? Arel.star.count : Arel.star.countIf(measure.condition_query model, arel_table, cube_query)
        end
      else
        define_method fname do |model, arel_table, measure, cube_query|
          column = arel_table[self.class.column_name.to_sym]
          measure.selectors.empty? ? column.send(fname) : column.send(fname.to_s+'If', measure.condition_query(model, arel_table, cube_query))
        end
      end


    end


  end
end