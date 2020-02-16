module Activecube
  module QueryMethods

    [:slice, :measure, :when].each do |method|
      define_method(method) do |*args|
        Query::CubeQuery.new(self).send method, *args
      end
    end

  end
end
