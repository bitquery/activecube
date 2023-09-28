require 'activecube/processor/template'

module Activecube::Query
  class Slice < Item
    attr_reader :dimension, :parent, :selectors
    attr_accessor :query_with_group_by

    def initialize(cube, key, definition, parent = nil, selectors = [])
      super cube, key, definition
      @dimension = parent ? parent.dimension : definition
      @parent = parent

      @selectors = selectors

      return unless parent
      raise "Unexpected class #{definition.class.name}" unless definition.is_a?(Activecube::Field)

      field_methods! if definition.class < Activecube::Field
    end

    def required_column_names
      ((dimension.class.column_names || []) + selectors.map(&:required_column_names)).flatten.uniq
    end

    def [](arg)
      key = arg.to_sym

      child = if definition.is_a?(Activecube::Dimension) && definition.class.fields && (fdef = definition.class.fields[key])
                Activecube::Field.build key, fdef
              elsif definition.is_a?(Activecube::Field) && (hash = definition.definition).is_a?(Hash)
                Activecube::Field.build key, hash[key]
              end

      raise Activecube::InputArgumentError, "Field #{key} is not defined for #{definition}" unless child

      if child.is_a?(Class) && child <= Activecube::Field
        child = child.new key
      elsif !child.is_a?(Activecube::Field)
        child = Activecube::Field.new(key, child)
      end

      Slice.new cube, key, child, self
    end

    def alias!(new_key)
      self.class.new cube, new_key, definition, parent, selectors
    end

    def when(*args)
      append(*args, @selectors, Selector, cube.selectors)
    end

    def group_by_columns
      if dimension.class.identity
        ([dimension.class.identity] + dimension.class.column_names).uniq
      else
        [key]
      end
    end

    def append_query(model, cube_query, table, query)
      query = append_with!(model, cube_query, table, query)

      attr_alias = "`#{key}`"
      expr = expression(model, table, self, cube_query)

      if parent || definition.respond_to?(:expression)
        expr = process_templates(expr)
      end

      query = query.project(expr.as(attr_alias))

      if dimension.class.identity
        expr = dimension.class.identity_expression
        group_by_columns.each do |column|
          node = if column == dimension.class.identity && expr
                   Arel.sql(expr).as(column)
                 else
                   table[column]
                 end

          query = query.project(node) unless query.projections.include?(node)

          query = query.group(expr ? column : table[column]) if query_with_group_by
        end
      elsif query_with_group_by
        query = query.group(attr_alias)
      end

      query = query.order(attr_alias) if cube_query.orderings.empty?

      selectors.each do |selector|
        selector.append_query model, cube_query, table, query
      end

      query
    end

    def process_templates(text)
      template = Activecube::Processor::Template.new(text)
      return text unless template.template_specified?

      if query_with_group_by
        return template.apply_template('any')
      end

      template.apply_template('empty')
    end

    def to_s
      parent ? "Dimension #{dimension}[#{super}]" : "Dimension #{super}"
    end

    def field_methods!
      excluded = [:expression] + self.class.instance_methods(false)
      definition.class.instance_methods(false).each do |name|
        next if excluded.include?(name)

        define_singleton_method name do |*args|
          definition.send name, *args
          self
        end
      end
    end

    private

    def expression(model, arel_table, slice, cube_query)
      if parent || definition.respond_to?(:expression)
         Arel.sql(definition.expression(model, arel_table, slice, cube_query))
       else
         arel_table[dimension.class.column_name]
       end
    end
  end
end
