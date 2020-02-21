module Activecube::Query
  class Selector < Item

    OPERATORS = ['eq','ne','gt','lt','gteq','lteq','in','not_in','between']
    ARRAY_OPERATORS = ['in','not_in']

    class Operator

      attr_reader :operation, :argument

      def initialize operation, argument
        @operation = operation
        @argument = argument
      end

      def expression left, right
        left.send(operation, right)
      end

      def eql?(other)
        return other.kind_of?(Operator) &&
            self.operation==other.operation &&
            self.argument == other.argument
      end

      def == other
        eql? other
      end

      def hash
        self.operation.hash + self.argument.hash
      end

    end


    attr_reader :operator
    def initialize cube, key, definition, operator = nil
      super cube, key, definition
      @operator = operator
    end

    OPERATORS.each do |method|
      define_method(method) do |*args|
        if ARRAY_OPERATORS.include? method
          @operator = Operator.new(method, args)
        elsif method=='between'
          if args.kind_of?(Range)
            @operator = Operator.new(method, args)
          elsif args.kind_of?(Array) && (arg = args.flatten).count==2
            @operator = Operator.new(method, arg[0]..arg[1])
          else
            raise ArgumentError, "Unexpected size of arguments for #{method}, must be Range or Array of 2"
          end
        else
          raise ArgumentError, "Unexpected size of arguments for #{method}" unless args.size==1
          @operator = Operator.new(method, args.first)
        end
        self
      end
    end

    alias_method :since, :gteq
    alias_method :till, :lteq
    alias_method :is, :eq
    alias_method :after, :gt
    alias_method :before, :lt

    def alias! new_key
      self.class.new cube, new_key, definition, operator
    end

    def append_query cube_query, table, query
      query.where(expression table, cube_query)
    end

    def expression arel_table, cube_query
      definition.expression arel_table, self, cube_query
    end

    def eql?(other)
      return other.kind_of?(Selector) &&
          self.cube==other.cube &&
          self.operator == other.operator &&
          self.definition.class == other.definition.class
    end

    def == other
      eql? other
    end

    def hash
      self.definition.class.hash + self.operator.hash
    end

  end
end
