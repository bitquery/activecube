module Activecube
  module Processor
    class Index
      attr_reader :fields, :cardinality, :required, :indexes

      def initialize(name, *args)
        @fields = [name].flatten
        @cardinality = args.first && args.first[:cardinality]
        @required = args.first && args.first[:required]
        # if true this index will definitely be used
        @indexes = args.first && args.first[:indexes]
      end

      def indexes?(query, measures)
        indexes || (fields - query.selector_column_names(measures)).empty?
      end

      def matches?(query, measures)
        !required || (fields - query.column_names_required(measures)).empty?
      end
    end
  end
end