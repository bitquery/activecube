module Activecube::Query
  class CubeQuery

    include ChainAppender

    attr_reader :cube, :slices, :measures, :selectors, :orderings, :options
    def initialize cube, slices = [], measures = [], selectors = [], options = []
      @cube = cube
      @slices = slices
      @measures = measures
      @selectors = selectors
      @options = options
    end

    def slice *args
      append *args, @slices, Slice, cube.dimensions
    end

    def measure *args
      append *args, @measures, Measure, cube.metrics
    end

    def select *args
      append *args, @selectors, Selector, cube.selectors
    end

    def desc *args
      args.each{|arg|
        options << Ordering.new(arg, :desc)
      }
      self
    end

    def asc *args
      args.each{|arg|
        options << Ordering.new( arg, :asc)
      }
      self
    end

    def skip *args
      args.each{|arg|
        options << Limit.new( arg, :skip)
      }
      self
    end

    def take *args
      args.each{|arg|
        options << Limit.new( arg, :take)
      }
      self
    end

    def query
      composer = Activecube::Processor::Composer.new(self)
      sql = composer.build_query.to_sql
      composer.connection.exec_query(sql)
    end

    def to_query
      Activecube::Processor::Composer.new(self).build_query
    end

    def to_sql
      to_query.to_sql
    end

    def column_names measures = self.measures
      (measures + slices + selectors).map(&:required_column_names).flatten.uniq
    end

    def selector_column_names measures = self.measures
      (measures.map(&:selectors) + selectors).flatten.map(&:required_column_names).flatten.uniq
    end

    def reduced other_measures

      common_selectors = []
      other_measures.each_with_index do |m,i|
        if i==0
          common_selectors += m.selectors
        else
          common_selectors &= m.selectors
        end
      end

      if common_selectors.empty?
        reduced_measures = other_measures
        reduced_selectors = self.selectors
      else
        reduced_measures = other_measures.collect{|m|
          Measure.new m.cube, m.key, m.definition, (m.selectors - common_selectors)
        }
        reduced_selectors = self.selectors + common_selectors
      end

      unless reduced_measures.detect{|rm| rm.selectors.empty? }
        reduced_selectors += [OrSelector.new(reduced_measures.map(&:selectors).flatten.uniq)]
      end

      return self if (reduced_measures == self.measures) && (reduced_selectors == self.selectors)

      CubeQuery.new cube, slices, reduced_measures, reduced_selectors
    end

    def join_fields
      slices.map{|s| s.dimension_class.identity || s.key }.uniq
    end

  end
end