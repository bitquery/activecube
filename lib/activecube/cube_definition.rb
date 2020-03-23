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
        v.nil? ? nil : @entry_class.new(@cube, key, v.new)
      end

    end

    attr_reader :dimensions, :metrics, :selectors, :models

    def inspect
      name +
          (@dimensions && " Dimensions: #{@dimensions.keys.join(',')}")+
          (@metrics && " Metrics: #{@metrics.keys.join(',')}")+
          (@selectors && " Selectors: #{@selectors.keys.join(',')}")+
          (@models && " Models: #{@models.map(&:name).join(',')}")
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
      store_definition_array! 'model', (@models ||= []), [*args].flatten.map{|t| t }
    end

    def dim_column column_name
      Class.new(Activecube::Dimension) do
        column column_name
      end
    end

    def select_column column_name
      Class.new(Activecube::Selector) do
        column column_name
      end
    end

    def store_definition_map! name, map, data
      data.each_pair do |key, class_def|
        raise DefinitionError, "#{key} already defined for #{name}" if map.has_key?(key)
        map[key] = class_def
      end
    end

    def store_definition_array! name, array, data
      values = data & array
      raise DefinitionError, "#{values.join(',')} already defined for #{name}" unless values.empty?
      array.concat data
    end

  end
end