require 'active_support/concern'

module Activecube::ActiveRecordExtension

  extend ActiveSupport::Concern

  class_methods do

    attr_reader :activecube_indexes
    private
    def index index_name, *args
      (@activecube_indexes ||= []) << Activecube::Processor::Index.new(index_name,*args)
    end

  end

end
