module Activecube::Processor
  class Table

    attr_reader :model

    def initialize model
      @model = model
    end

    def name
      model.table_name
    end

    def matches? query, measures = query.measures
      (query.column_names(measures)-model.attribute_types.keys).empty?
    end

    def measures? measure
      (measure.required_column_names - model.attribute_types.keys).empty?
    end

    def query cube_query

      table = model.arel_table
      query = table

      (cube_query.slices + cube_query.measures + cube_query.selectors + cube_query.options).each do |s|
        query = s.append_query cube_query, table, query
      end

      query
    end

    def join cube_query, left_query, right_query

      outer_table = model.arel_table.class.new('').project(Arel.star)

      dimension_names = cube_query.join_fields

      query = outer_table.from(left_query).
          join(right_query, ::Arel::Nodes::FullOuterJoin).
          using(*dimension_names)

      cube_query.options.each do |option|
        query = option.append_query cube_query, outer_table, query
      end


      query
    end


  end
end