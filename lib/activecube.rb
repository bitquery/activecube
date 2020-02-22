require "activecube/version"
require 'activecube/active_record_extension'

require 'activecube/base'
require 'activecube/dimension'
require 'activecube/metric'
require 'activecube/selector'

require 'activecube/common/metrics'

require 'active_record'

module Activecube

  # include the extension
  ActiveRecord::Base.send(:include, Activecube::ActiveRecordExtension)

end
