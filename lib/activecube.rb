require "activecube/version"
require 'activecube/active_record_extension'

module Activecube
  class Error < StandardError; end

  # include the extension
  ActiveRecord::Base.send(:include, Activecube::ActiveRecordExtension)

end
