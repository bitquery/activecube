module Activecube::Query
  class Slice < Item

    attr_reader :dimension, :parent
    def initialize cube, key, definition, parent = nil
      super cube, key, definition
      @dimension = parent ? parent.dimension : definition
      @parent = parent
    end

    def required_column_names
      dimension.class.column_names || []
    end

    def [] key

      child = if definition.kind_of? Activecube::Dimension
                definition.class.fields[key]
              elsif definition.kind_of?(Activecube::Field) && (hash = definition.definition).kind_of?(Hash)
                hash[key]
              end

      raise "Field #{key} is not defined for #{definition}" unless child

      if child.kind_of?(Class) && child <= Activecube::Field
        child = child.new key
      elsif !child.kind_of?(Activecube::Field)
        child = Activecube::Field.new(key, child)
      end

      Slice.new cube, key, child, self

    end

    def alias! new_key
      self.class.new cube, new_key, definition, parent
    end

    def append_query model, cube_query, table, query

      attr_alias = "`#{key.to_s}`"
      expr = parent ?
                 Arel.sql(definition.expression(model, cube_query, table, query) ) :
                 table[dimension.class.column_name]

      query = query.project(expr.as(attr_alias))

      if identity = dimension.class.identity
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
      parent ? "Dimension #{dimension}[#{super}]" : "Dimension #{super}"
    end

    def respond_to? method, include_private = false
      definition.kind_of?(Activecube::Field) && definition.class!=Activecube::Field && definition.respond_to?(method)
    end

    def method_missing method, *args
      definition.send method, *args
      self
    end

  end
end