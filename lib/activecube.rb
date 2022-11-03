require 'activecube/version'
require 'activecube/active_record_extension'

require 'activecube/input_argument_error'
require 'activecube/base'
require 'activecube/view'
require 'activecube/dimension'
require 'activecube/metric'
require 'activecube/selector'

require 'activecube/common/metrics'

require 'active_record'

module Activecube
  # include the extension
  ActiveRecord::Base.include Activecube::ActiveRecordExtension
end
