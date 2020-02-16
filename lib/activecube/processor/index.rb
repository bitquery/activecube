module Activecube
  module Processor
    class Index

      attr_reader :fields, :cardinality
      def initialize name, *args
        @fields = [name].flatten
        @cardinality = args.first && args.first[:cardinality]
      end

      def indexes? query, measures
        (fields - query.selector_column_names(measures)).empty?
      end

    end
  end
end