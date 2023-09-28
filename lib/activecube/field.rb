module Activecube
  class Field
    attr_accessor :name, :definition

    def self.build(name, arg)
      if arg.is_a? String
        Field.new name, arg
      elsif arg.is_a? Hash
        Field.new name, arg.symbolize_keys
      elsif arg.is_a?(Class) && arg < Field
        arg.new name
      else
        raise Activecube::InputArgumentError, "Unexpected field #{name} definition with #{arg.class.name}"
      end
    end

    def initialize(name, arg = nil)
      @name = name
      @definition = arg
    end

    def expression(_model, _arel_table, _slice, _cube_query)
      unless definition.is_a?(String)
        raise Activecube::InputArgumentError,
              "String expression expected for #{name} field, instead #{definition.class.name} is found"
      end

      definition
    end
  end
end
