module Activecube::Query
  class Item

    include ChainAppender

    attr_reader :cube, :key, :definition
    def initialize cube, key, definition
      @key = key
      @cube = cube
      @definition = definition
    end

    def required_column_names
      definition.class.column_names || []
    end

    def alias! new_key
      self.class.new cube, new_key, definition
    end

    def to_s
      "#{definition.class.name}(#{key})"
    end

  end
end