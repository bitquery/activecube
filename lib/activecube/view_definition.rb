require 'active_support/concern'

module Activecube::ViewDefinition

    attr_reader :activecube_indexes, :models

    def index index_name, *args
      (@activecube_indexes ||= []) << Activecube::Processor::Index.new(index_name,*args)
    end

    def table x
      (@models ||= []) << x
    end


end
