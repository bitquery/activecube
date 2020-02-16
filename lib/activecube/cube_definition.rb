module Activecube
  module CubeDefinition

    class DefinitionError < ::StandardError
    end

    class NamedHash < Hash

      def initialize cube, entry_class
        @cube = cube
        @entry_class = entry_class
      end

      def [] key
        v = super key
        v.nil? ? nil : @entry_class.new(@cube, key, v)
      end

    end

    attr_reader :dimensions, :metrics, :selectors, :tables

    def inspect
      name +
          (@dimensions && " Dimensions: #{@dimensions.keys.join(',')}")+
          (@metrics && " Metrics: #{@metrics.keys.join(',')}")+
          (@selectors && " Selectors: #{@selectors.keys.join(',')}")+
          (@tables && " Tables: #{@tables.map(&:name).join(',')}")
    end

    private

    def dimension data
      store_definition_map! 'dimension', (@dimensions ||= NamedHash.new(self, Query::Slice) ), data
    end

    def metric data
      store_definition_map! 'metric', (@metrics ||= NamedHash.new(self, Query::Measure)), data
    end

    def selector data
      store_definition_map! 'filter', (@selectors ||= NamedHash.new(self, Query::Selector)), data
    end

    def table *args
      store_definition_array! 'table', (@tables ||= []), [*args].flatten.map{|t| Processor::Table.new t }
    end

    def store_definition_map! name, map, data
      data.each_pair do |key, class_def|
        raise DefinitionError, "#{key} already defined for #{name}" if map.has_key?(key)
        map[key] = class_def.new
      end
    end

    def store_definition_array! name, array, data
      values = data & array
      raise DefinitionError, "#{values.join(',')} already defined for #{name}" unless values.empty?
      array.concat data
    end
  end
end