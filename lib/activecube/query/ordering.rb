module Activecube
  module Query
    class Ordering
      attr_reader :argument, :direction, :options

      def initialize(argument, direction, options = {})
        @argument = argument
        @direction = direction
        @options = options
      end

      def append_query(_model, _cube_query, _table, query)
        @text = argument.to_s.split(',').map { |s| quote s }.join(',')

        return by_length_order(query) if options[:with_length]

        simple_order(query)
      end

      def quote(s)
        if /^[\w.]+$/.match?(s)
          "`#{s}`"
        else
          s
        end
      end

      private

      attr_reader :text

      def simple_order(query)
        query.order(::Arel.sql(text).send(direction))
      end

      def by_length_order(query)
        query.order(
          ::Arel.sql("LENGTH(#{text})").send(direction),
          ::Arel.sql(text).send(direction)
        )
      end
    end
  end
end
