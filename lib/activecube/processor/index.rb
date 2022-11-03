module Activecube
  module Processor
    class Index
      attr_reader :fields, :cardinality, :required

      def initialize(name, *args)
        @fields = [name].flatten
        @cardinality = args.first && args.first[:cardinality]
        @required = args.first && args.first[:required]
      end

      def indexes?(query, measures)
        (fields - query.selector_column_names(measures)).empty?
      end

      def matches?(query, measures)
        !required || (fields - query.column_names_required(measures)).empty?
      end
    end
  end
end
