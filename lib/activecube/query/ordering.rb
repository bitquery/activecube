module Activecube
  module Query
    class Ordering

      attr_reader :argument, :direction
      def initialize argument, direction
        @argument = argument
        @direction = direction
      end

      def append_query _model, _cube_query, _table, query
        text = argument.to_s.split(',').map{|s| quote s}.join(',')
        query.order(::Arel.sql(text).send(direction))
      end

      def quote s
        if s =~ /^[\w\.]+$/
          "`#{s}`"
        else
          s
        end
      end

    end
  end
end