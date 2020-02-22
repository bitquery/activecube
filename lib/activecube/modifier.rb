module Activecube
  class Modifier

    attr_reader :name, :definition
    def initialize *args
      @name = args.first
      @definition = args.second
    end


  end
end