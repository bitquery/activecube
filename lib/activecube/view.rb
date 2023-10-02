require 'activecube/view_definition'
require 'activecube/view_connection'

module Activecube
  class View
    extend ViewDefinition
    extend ViewConnection

    def model
      self.class
    end

    def name
      model.name
    end

    def matches?(query, _measures = query.measures)
      true
    end

    def measures?(_measure)
      true
    end

    def query(_cube_query, _measures = _cube_query.measures)
      raise "query method have to be implemented in #{name}"
    end

    def join(_cube_query, _left_query, _right_query)
      raise "join method have to be implemented in #{name}"
    end

    private

    def dimension_include_group_by?(slice)
      slice.dimension_include_group_by
    end

    def any_metrics_specified?(measures)
      # that means if there are no measures in the query, we don't need to group by.
      return false if measures.first.is_a?(Activecube::Query::MeasureNothing)

      true
    end
  end
end
