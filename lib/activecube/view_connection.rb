require 'active_support/concern'

module Activecube::ViewConnection
  attr_reader :connection

  def connect_to(connection)
    @connection = connection
  end
end
