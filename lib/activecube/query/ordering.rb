module Activecube
  module Query
    class Ordering
      attr_reader :argument, :direction, :options

      def initialize(argument, direction, options = {})
        @argument = argument
        @direction = direction
        @options = options
      end

      def append_query(_model, cube_query, _table, query)
        allowed_sort_keys = (cube_query.measures + cube_query.slices).to_h { |k| [k.key, true] }

        sort_keys = []
        # allow ordering like desc: "key1,key2" for backward compatibility
        argument.to_s.delete(' ').split(',').each do |s|
          prefixed_s = Activecube::Graphql::ParseTree::Element::KEY_FIELD_PREFIX + s

          if allowed_sort_keys[s]
            sort_keys << quote(s)
          elsif allowed_sort_keys[prefixed_s]
            sort_keys << quote(prefixed_s)
          else
            key_wo_prefix = s.delete_prefix(Activecube::Graphql::ParseTree::Element::KEY_FIELD_PREFIX)
            raise GraphqlError::ArgumentError, "Can't use #{key_wo_prefix} in sorting. Missing field #{key_wo_prefix} in executed query"
          end
        end

        @text = sort_keys.join(',')

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
