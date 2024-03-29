require 'activecube/processor/index'
require 'activecube/processor/measure_tables'
require 'activecube/processor/optimizer'
require 'activecube/processor/table'
require 'activecube/query/measure_nothing'

module Activecube::Processor
  class Composer
    attr_reader :cube_query, :models, :query

    def initialize(cube_query)
      @cube_query = cube_query
    end

    def build_query
      @query = compose_queries optimize! ranked_tables
    end

    def connection
      connections = models.map(&:connection).compact.uniq
      # for views
      if connections.empty? && !models.empty?
        connections = models.first&.models&.map(&:connection)&.compact&.uniq || []
      end
      raise 'No connection found for query' if connections.empty?
      if connections.count > 1
        raise "Tables #{models.map(&:name).join(',')} mapped to multiple connections, can not query"
      end

      connections.first
    end

    private

    def optimize!(measure_tables)
      all_tables = measure_tables.map(&:tables).map(&:keys).flatten.uniq

      cost_matrix = measure_tables.collect do |measure_table|
        all_tables.collect do |table|
          measure_table.tables[table].try(&:cost)
        end
      end

      before = total_cost measure_tables
      Optimizer.new(cost_matrix).optimize.each_with_index do |optimal, index|
        measure_tables[index].selected = measure_tables[index].entries.map(&:table).index(all_tables[optimal])
      end
      after = total_cost measure_tables

      raise "Optimizer made it worse #{before} -> #{after} for #{cost_matrix}" unless after <= before

      measure_tables
    end

    def total_cost(measure_tables)
      measure_tables.group_by(&:table).collect { |t| t.second.map(&:entry).map(&:cost).max }.sum
    end

    def ranked_tables
      tables = cube_query.tables.select { |table| table.matches? cube_query, [] }
      measures = if cube_query.measures.empty?
                   [Activecube::Query::MeasureNothing.new(cube_query.cube)]
                 else
                   cube_query.measures
                 end
      measures.collect do |measure|
        by = MeasureTables.new measure
        tables.each do |table|
          next unless table.measures? measure

          max_cardinality_index = table.model.activecube_indexes.select do |index|
            index.indexes? cube_query, [measure]
          end.sort_by(&:cardinality).last
          by.add_table table, max_cardinality_index
        end
        if by.tables.empty?
          raise "Metric #{measure.key} #{measure.definition.try(:name) || measure.class.name} can not be measured by any of tables #{tables.map(&:name).join(',')}"
        end

        by
      end
    end

    def compose_queries(measure_tables)
      composed_query = nil
      @models = []
      measures_by_tables = measure_tables.group_by(&:table)
      measures_by_tables.each_pair do |table, list|
        @models << table.model
        table_query = table.query cube_query, list.map(&:measure)
        composed_query = composed_query ? table.join(cube_query, composed_query, table_query) : table_query
      end
      composed_query
    end
  end
end
