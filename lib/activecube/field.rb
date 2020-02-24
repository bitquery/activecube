module Activecube
  class Field

    attr_reader :name, :definition

    def self.build name, arg
      if arg.kind_of? String
        Field.new name, arg
      elsif arg.kind_of? Hash
        Field.new name, arg.symbolize_keys
      elsif arg.kind_of?(Class) && arg < Field
        arg.new name
      else
        raise ArgumentError, "Unexpected field #{name} definition with #{arg.class.name}"
      end
    end

    def initialize name, arg = nil
      @name = name
      @definition = arg
    end

    def expression _model, _arel_table, _slice, _cube_query
      raise ArgumentError, "String expression expected for #{name} field, instead #{definition.class.name} is found" unless definition.kind_of?(String)
      definition
    end

  end


end