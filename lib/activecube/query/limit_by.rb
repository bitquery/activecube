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

      def append_query(_model, cube_query, _table, query)
        allowed_limit_by = (cube_query.measures + cube_query.slices).to_h { |k| [k.key, true] }

        limit_by = []
        # allow limit by like by: "key1,key2" for backward compatibility
        each.delete(' ').split(',').each do |s|
          prefixed_s = Activecube::Graphql::ParseTree::Element::KEY_FIELD_PREFIX + s

          if allowed_limit_by[s]
            limit_by << quote(s)
          elsif allowed_limit_by[prefixed_s]
            limit_by << quote(prefixed_s)
          else
            key_wo_prefix = s.delete_prefix(Activecube::Graphql::ParseTree::Element::KEY_FIELD_PREFIX)
            raise GraphqlError::ArgumentError, "Can't use #{key_wo_prefix} in limit by. Missing field #{key_wo_prefix} in executed query"
          end
        end

        new_each = limit_by.join(',')
        query.limit_by new_each, limit, offset
      end

      def quote(s)
        if /^[\w.]+$/.match?(s)
          "`#{s}`"
        else
          s
        end
      end
    end
  end
end
