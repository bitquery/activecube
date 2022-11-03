module Activecube::Query
  module ChainAppender
    private

    def append(*args, list, def_class, definitions)
      list.concat args.map { |arg|
        if arg.is_a?(Symbol) && definitions
          definitions[arg]
        elsif arg.is_a?(def_class)
          arg
        elsif arg.is_a? Hash
          arg.collect do |pair|
            unless pair.second.is_a?(def_class)
              raise Activecube::InputArgumentError,
                    "Unexpected #{pair.second.class.name} to use for #{def_class} as #{arg}[#{pair.first}]"
            end

            pair.second.alias! pair.first
          end
        else
          raise Activecube::InputArgumentError, "Unexpected #{arg.class} to use for #{def_class} as #{arg}"
        end
      }.flatten
      self
    end
  end
end
