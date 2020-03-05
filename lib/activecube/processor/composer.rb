require 'activecube/processor/index'
require 'activecube/processor/measure_tables'
require 'activecube/processor/optimizer'
require 'activecube/processor/table'
require 'activecube/query/measure_nothing'

module Activecube::Processor
  class Composer

    attr_reader :cube_query, :models
    def initialize cube_query
      @cube_query = cube_query
    end

    def build_query
      compose_queries optimize! ranked_tables
    end

    def connection
      connections = models.map(&:connection).compact.uniq
      raise "No connection found for query" if connections.empty?
      raise "Tables #{models.map(&:name).join(',')} mapped to multiple connections, can not query" if connections.count>1
      connections.first
    end

    private

    def optimize! measure_tables

      all_tables = measure_tables.map(&:tables).map(&:keys).flatten.uniq

      cost_matrix = measure_tables.collect do |measure_table|
        all_tables.collect{|table|
          measure_table.tables[table].try(&:cost)
        }
      end

      before = total_cost measure_tables
      Optimizer.new(cost_matrix).optimize.each_with_index do |optimal, index|
        measure_tables[index].selected = optimal
      end
      after = total_cost measure_tables

      raise "Optimizer made it worth #{before} -> #{after} for #{cost_matrix}" unless after <= before
      measure_tables

    end

    def total_cost measure_tables
      measure_tables.group_by(&:table).collect{|t| t.second.map(&:entry).map(&:cost).max }.sum
    end

    def ranked_tables
      tables = cube_query.tables.select{|table| table.matches? cube_query, []}
      measures = cube_query.measures.empty? ?
                     [Activecube::Query::MeasureNothing.new(cube_query.cube)] :
                     cube_query.measures
      measures.collect do |measure|
        by = MeasureTables.new measure
        tables.each{|table|
          next unless table.measures? measure
          max_cardinality_index = table.model.activecube_indexes.select{|index|
            index.indexes? cube_query, [measure]
          }.sort_by(&:cardinality).last
          by.add_table table, max_cardinality_index
        }
        raise "Metric #{measure.key} #{measure.definition.name} can not be measured by any of tables #{tables.map(&:name).join(',')}" if by.tables.empty?
        by
      end
    end

    def compose_queries measure_tables
      composed_query  = nil
      @models = []
      measure_tables.group_by(&:table).each_pair do |table, list|
        @models << table.model
        reduce_options = measure_tables.count==1 ? cube_query.options : []
        reduced = cube_query.reduced list.map(&:measure), reduce_options
        table_query = table.query reduced
        composed_query = composed_query ? table.join(cube_query, composed_query, table_query) : table_query
      end
      composed_query
    end

  end
end