module Activecube
  module Query
    class Option

      attr_reader :argument, :value
      def initialize argument, value
        @argument = argument
        @value = value
      end

      def append_query _model, _cube_query, _table, query
        query
      end

    end
  end
end