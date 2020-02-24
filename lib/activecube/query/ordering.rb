module Activecube
  module Query
    class Ordering

      attr_reader :argument, :direction
      def initialize argument, direction
        @argument = argument
        @direction = direction
      end

      def append_query _model, _cube_query, _table, query
        text = argument.to_s.split(',').map{|s| "`#{s}`"}.join(',')
        query.order(::Arel.sql(text).send(direction))
      end

    end
  end
end