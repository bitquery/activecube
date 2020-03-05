module Activecube::Query
  module ChainAppender
    private

    def append *args, list, def_class, definitions
      list.concat args.map{|arg|
        if arg.kind_of?(Symbol) && definitions
          definitions[arg]
        elsif arg.kind_of?(def_class)
          arg
        elsif arg.kind_of? Hash
          arg.collect{|pair|
            raise Activecube::InputArgumentError, "Unexpected #{pair.second.class.name} to use for #{def_class} as #{arg}[#{pair.first}]" unless pair.second.kind_of?(def_class)
            pair.second.alias! pair.first
          }
        else
          raise Activecube::InputArgumentError, "Unexpected #{arg.class} to use for #{def_class} as #{arg}"
        end
      }.flatten
      self
    end


  end
end
