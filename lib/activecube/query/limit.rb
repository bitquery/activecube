module Activecube
  module Query
    class Limit

      attr_reader :argument, :option
      def initialize argument, option
        @argument = argument
        @option = option
      end

      def append_query _cube_query, _table, query
        query.send(option,argument)
      end

    end
  end
end