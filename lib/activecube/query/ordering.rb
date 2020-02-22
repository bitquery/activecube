module Activecube
  module Query
    class Ordering

      attr_reader :argument, :direction
      def initialize argument, direction
        @argument = argument
        @direction = direction
      end

      def append_query _model, _cube_query, _table, query
        query.order(::Arel.sql(argument.to_s).send(direction))
      end

    end
  end
end