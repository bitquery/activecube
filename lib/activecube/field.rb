module Activecube
  class Field

    attr_reader :name, :definition
    def initialize *args
      @name = args.first
      @definition = args.second
    end


  end
end