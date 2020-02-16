module Activecube
  module Processor
    class MeasureTables

      class Entry
        attr_reader :table, :index, :cardinality, :cost
        def initialize table, index
          @table = table
          @index = index
          @cardinality = index ? index.cardinality : 0
          @cost = 1.0 / (1.0 + cardinality)
        end
      end

      attr_reader :measure, :entries, :tables
      attr_accessor :selected

      def initialize measure
        @measure = measure
        @tables = {}
        @entries = []
        @selected = 0
      end


      def add_table table, index
        e = Entry.new(table, index)
        entries << e
        tables[table] = e
      end

      def table
        entry.table
      end

      def entry
        entries[selected]
      end

    end
  end
end