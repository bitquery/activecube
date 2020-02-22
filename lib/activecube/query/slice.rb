module Activecube::Query
  class Slice < Item

    attr_reader :field, :modifier
    def initialize cube, key, dimension, field = nil, modifier = nil
      super cube, key, dimension
      @field = field
      @modifier = modifier
      field_methods! if field.try(:definition).kind_of?(Hash)
    end

    def [] key
      unless (definition.kind_of? Activecube::Dimension) && !self.field && (field = definition.class.fields[key])
        raise "Field #{key} is not defined for #{definition.name}"
      end
      Slice.new cube, key, definition, field
    end

    def alias! new_key
      self.class.new cube, new_key, definition, field, modifier
    end

    def dimension_class
      definition.class
    end

    def append_query _model, cube_query, table, query

      attr_alias = "`#{key.to_s}`"
      expr = field ? Arel.sql( modifier || field.definition ) : table[dimension_class.column_name]
      query = query.project(expr.as(attr_alias))

      if identity = dimension_class.identity
        query = query.project(table[identity]).group(table[identity])
      else
        query = query.group(attr_alias)
      end

      if cube_query.orderings.empty?
        query = query.order(attr_alias)
      end

      query
    end

    def to_s
      "Dimension #{super}"
    end


    private

    def field_methods!
      field.definition.each_pair do |k,v|
        if v.kind_of? Proc
          define_singleton_method k, ((proc {|x| @modifier = x; self}) << v)
        elsif v.kind_of? String
          define_singleton_method k do @modifier = v; self end
        else
          raise "Unexpected type #{k.class.name} for definition of #{name}[#{k}]"
        end
      end
    end

  end
end