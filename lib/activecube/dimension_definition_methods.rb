module Activecube
  module DimensionDefinitionMethods

    attr_reader :column_names, :identity, :fields

    def column_name
      raise "Not defined column for a metric #{self.name}" if column_names.empty?
      raise "Defined more than one column for a metric #{self.name}" if column_names.count>1
      column_names.first
    end

    private

    def column *args
      array = (@column_names ||= [] )
      data = [*args].flatten
      values = data & array
      raise DefinitionError, "#{values.join(',')} already defined for columns in #{self.name}" unless values.empty?
      array.concat data
    end

    def field *args
      (@fields ||= {} )[args.first.to_sym] = Field.new( *args)
    end

    def identity_column *args
      raise "Identity already defined as #{identity} for #{self.name}" if @identity
      @identity = args.first
    end

  end
end