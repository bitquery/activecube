require 'activecube/modifier'
module Activecube
  module Query
    class Modification

      attr_reader :modifier, :args
      def initialize modifier, *args
        @modifier = modifier
        @args = args
      end

    end
  end
end