require 'activecube/cube_definition'
require 'activecube/field'
require 'activecube/modifier'

module Activecube
  module DefinitionMethods
    attr_reader :column_names

    def column_name
      raise "Not defined column for a dimension or metric #{name}" if !column_names || column_names.empty?
      raise "Defined more than one column for a dimension or metric #{name}" if column_names.count > 1

      column_names.first
    end

    private

    def column(*args)
      array = (@column_names ||= [])
      data = [*args].flatten
      values = data & array
      raise DefinitionError, "#{values.join(',')} already defined for columns in #{name}" unless values.empty?

      array.concat data
    end
  end

  module DimensionDefinitionMethods
    include DefinitionMethods

    attr_reader :identity, :identity_expression, :fields

    private

    def identity_column(*args)
      raise "Identity already defined as #{identity} for #{name}" if @identity

      @identity = args.first
      @identity_expression = args.second
    end

    def field(*args)
      name = args.first.to_sym
      (@fields ||= {})[name] = args.second
    end
  end

  module MetricDefinitionMethods
    include DefinitionMethods

    attr_reader :modifiers, :tuple

    private

    def modifier(*args)
      (@modifiers ||= {})[args.first.to_sym] = Modifier.new(*args)
    end

    def tuple_fields(*args)
      @tuple = args
    end
  end
end
