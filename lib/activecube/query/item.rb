module Activecube::Query
  class Item

    include ChainAppender

    attr_reader :cube, :key, :definition
    def initialize cube, key, definition
      @key = key
      @cube = cube
      @definition = definition
    end

    def required_column_names
      definition.class.column_names || []
    end

    def alias! new_key
      self.class.new cube, new_key, definition
    end

    def to_s
      "#{definition.class.name}(#{key})"
    end

    def append_with! model, cube_query, table, query

      if definition.respond_to?(:with_expression) &&
        (with_expression = definition.with_expression(model, cube_query, table, query))
        with_expression.each_pair do |key, expr|
          query = try_append_with(query, key, expr)
        end
      end
      query
    end

    private



    def try_append_with(query, key, expr)
      expr = Arel.sql(expr) if expr.kind_of?(String)
      query = query.where(Arel.sql('1')) unless query.respond_to?(:ast)
      if (with = query.ast.with)
        existing = with.expr.detect{|expr| expr.right==key }
        if existing
          raise "Key #{key} defined twice in WITH statement, with different expressions #{expr.to_sql} AND #{existing.left}" if existing.left!=expr.to_s
          query
        else
          query.with(with.expr + [expr.as(key)])
        end
      else
        query.with(expr.as(key))
      end

    end

  end
end