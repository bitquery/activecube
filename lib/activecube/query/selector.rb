module Activecube::Query
  class Selector < Item
    OPERATORS = %w[eq not_eq gt lt gteq lteq in not_in between]
    ARRAY_OPERATORS = %w[in not_in]
    ARRAY_OPERATOR_MAP = {
      'eq' => 'in',
      'not_eq' => 'not_in'
    }
    INDEX_OPERATORS = %w[eq in]

    class CombineSelector < Selector
      def initialize(selectors, operator)
        @selectors = selectors
        @operator = operator
      end

      def required_column_names
        @selectors.map(&:required_column_names).uniq
      end

      def to_s
        "Selector #{operator.operation}(#{@selectors.map(&:to_s).join(',')})"
      end

      def expression(model, arel_table, cube_query)
        expr = nil
        @selectors.each do |s|
          expr = if expr
                   expr.send(operator.operation,
                             s.expression(model, arel_table,
                                          cube_query))
                 else
                   s.expression(model, arel_table, cube_query)
                 end
        end
        expr
      end

      def append_query(model, cube_query, arel_table, query)
        @selectors.each do |s|
          query = s.append_with!(model, cube_query, arel_table, query)
        end

        query.where expression(model, arel_table, cube_query)
      end
    end

    class Operator
      attr_reader :operation, :argument

      def initialize(operation, argument)
        @operation = operation
        @argument = argument
      end

      def expression(_model, left, right)
        if right.is_a?(Array) && (matching_array_op = ARRAY_OPERATOR_MAP[operation])
          left.send(matching_array_op, right)
        else
          left.send(operation, right)
        end
      end

      def eql?(other)
        other.is_a?(Operator) &&
          operation == other.operation &&
          argument == other.argument
      end

      def ==(other)
        eql? other
      end

      def hash
        operation.hash + argument.hash
      end
    end

    attr_reader :operator

    def initialize(cube, key, definition, operator = nil)
      super cube, key, definition
      @operator = operator
    end

    OPERATORS.each do |method|
      define_method(method) do |*args|
        raise Activecube::InputArgumentError, "Selector for #{method} already set" if operator

        if ARRAY_OPERATORS.include? method
          @operator = Operator.new(method, args.flatten)
        elsif method == 'between'
          if args.is_a?(Range)
            @operator = Operator.new(method, args)
          elsif args.is_a?(Array) && (arg = args.flatten).count == 2
            @operator = Operator.new(method, arg[0]..arg[1])
          else
            raise Activecube::InputArgumentError,
                  "Unexpected size of arguments for #{method}, must be Range or Array of 2"
          end
        else
          raise Activecube::InputArgumentError, "Unexpected size of arguments for #{method}" unless args.size == 1

          @operator = Operator.new(method, args.first)
        end
        self
      end
    end

    alias since gteq
    alias till lteq
    alias is eq
    alias not not_eq
    alias after gt
    alias before lt

    def alias!(new_key)
      self.class.new cube, new_key, definition, operator
    end

    def append_query(model, cube_query, table, query)
      query = append_with!(model, cube_query, table, query)
      query.where(expression(model, table, cube_query))
    end

    def expression(model, arel_table, cube_query)
      definition.expression model, arel_table, self, cube_query
    end

    def eql?(other)
      other.is_a?(Selector) &&
        cube == other.cube &&
        operator == other.operator &&
        definition.class == other.definition.class
    end

    def ==(other)
      eql? other
    end

    def hash
      definition.class.hash + operator.hash
    end

    def to_s
      "Selector #{super}"
    end

    def is_indexed?
      INDEX_OPERATORS.include? operator&.operation
    end

    def self.or(selectors)
      CombineSelector.new(selectors, Operator.new(:or, nil))
    end

    def self.and(selectors)
      CombineSelector.new(selectors, Operator.new(:and, nil))
    end
  end
end
