require 'activecube/query/selector'

module Activecube
  module Query
    class OrSelector < Selector

      attr_reader :selectors
      def initialize selectors
        @selectors = selectors
      end

      def append_query cube_query, table, query
        expr = nil
        selectors.each do |s|
          expr = expr ? expr.or(s.expression table, cube_query) : s.expression(table, cube_query)
        end
        query.where(expr)
      end

    end
  end
end