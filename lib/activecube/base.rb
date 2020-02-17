require 'activecube/cube_definition'
require 'activecube/query_methods'

module Activecube
  class Base
    extend CubeDefinition
    extend QueryMethods
  end
end
