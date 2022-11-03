require 'activecube/query/measure'

module Activecube::Query
  class MeasureNothing < Measure
    def initialize(cube)
      super cube, nil, nil
    end

    def required_column_names
      []
    end

    def append_query(_model, _cube_query, _table, query)
      query
    end

    def to_s
      'Measure nothing, used for queries where no metrics defined'
    end
  end
end
