module Activecube::Query
  class Slice < Item

    attr_reader :dimension, :parent, :selectors
    def initialize cube, key, definition, parent = nil, selectors = []
      super cube, key, definition
      @dimension = parent ? parent.dimension : definition
      @parent = parent

      @selectors = selectors
      
      if parent
        raise "Unexpected class #{definition.class.name}" unless definition.kind_of?(Activecube::Field)
        field_methods! if definition.class < Activecube::Field
      end  
      
    end

    def required_column_names
      ((dimension.class.column_names || []) + selectors.map(&:required_column_names) ).flatten.uniq
    end

    def [] arg

      key = arg.to_sym

      child = if definition.kind_of? Activecube::Dimension
                definition.class.fields && definition.class.fields[key]
              elsif definition.kind_of?(Activecube::Field) && (hash = definition.definition).kind_of?(Hash)
                hash[key]
              end

      raise Activecube::InputArgumentError, "Field #{key} is not defined for #{definition}" unless child

      if child.kind_of?(Class) && child <= Activecube::Field
        child = child.new key
      elsif !child.kind_of?(Activecube::Field)
        child = Activecube::Field.new(key, child)
      end

      Slice.new cube, key, child, self

    end

    def alias! new_key
      self.class.new cube, new_key, definition,  parent, selectors
    end

    def when *args
      append *args, @selectors, Selector, cube.selectors
    end

    def group_by_columns
      if dimension.class.identity
        ([dimension.class.identity] + dimension.class.column_names).uniq
      else
        [key]
      end
    end

    def append_query model, cube_query, table, query

      attr_alias = "`#{key.to_s}`"
      expr = (parent || definition.respond_to?(:expression)) ?
                 Arel.sql(definition.expression( model, table, self, cube_query) ) :
                 table[dimension.class.column_name]

      query = query.project(expr.as(attr_alias))

      if dimension.class.identity
        group_by_columns.each do |column|
            query = query.project(table[column]).group(table[column])
        end
      else
        query = query.group(attr_alias)
      end

      if cube_query.orderings.empty?
        query = query.order(attr_alias)
      end

      selectors.each do |selector|
        selector.append_query model, cube_query, table, query
      end

      query
    end

    def to_s
      parent ? "Dimension #{dimension}[#{super}]" : "Dimension #{super}"
    end
    
    def field_methods!
      excluded = [:expression] + self.class.instance_methods(false)
      definition.class.instance_methods(false).each do |name|
        unless excluded.include?(name)
          define_singleton_method name do |*args|
            definition.send name, *args
            self
          end
        end
      end
    end
        

  end
end