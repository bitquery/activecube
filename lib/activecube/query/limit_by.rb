module Activecube
  module Query
    class LimitBy
      attr_reader :each, :limit, :offset

      def initialize(arguments)
        map = arguments.to_h
        @each = map[:each]
        @limit = map[:limit]
        @offset = map[:offset] || 0
      end

      def append_query(_model, _cube_query, _table, query)
        query.limit_by each, limit, offset
      end
    end
  end
end
