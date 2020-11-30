require 'activecube/query/chain_appender'
require 'activecube/query/item'
require 'activecube/query/limit'
require 'activecube/query/limit_by'
require 'activecube/query/measure'
require 'activecube/query/ordering'
require 'activecube/query/option'
require 'activecube/query/selector'
require 'activecube/query/slice'

require 'activecube/processor/composer'

module Activecube::Query
  class CubeQuery

    include ChainAppender

    attr_reader :cube, :slices, :measures, :selectors, :options, :tables, :sql
    def initialize cube, slices = [], measures = [], selectors = [], options = [], model_tables = nil
      @cube = cube
      @slices = slices
      @measures = measures
      @selectors = selectors
      @options = options

      @tables = model_tables || cube.models.map{|m|
        m < Activecube::View ? m.new : Activecube::Processor::Table.new(m)
      }

      cube.options && cube.options.each do |option|
        define_singleton_method option.to_s.underscore do |*args|
          @options << Option.new(option, *args)
          self
        end
      end

    end

    def slice *args
      clear_sql
      append *args, @slices, Slice, cube.dimensions
    end

    def measure *args
      clear_sql
      append *args, @measures, Measure, cube.metrics
    end

    def when *args
      clear_sql
      append *args, @selectors, Selector, cube.selectors
    end

    def desc *args
      clear_sql
      args.each{|arg|
        options << Ordering.new(arg, :desc)
      }
      self
    end

    def asc *args
      clear_sql
      args.each{|arg|
        options << Ordering.new( arg, :asc)
      }
      self
    end

    def offset *args
      clear_sql
      args.each{|arg|
        options << Limit.new( arg, :skip)
      }
      self
    end

    def limit *args
      clear_sql
      args.each{|arg|
        options << Limit.new( arg, :take)
      }
      self
    end

    def limit_by *args
      clear_sql
      options << LimitBy.new(args)
      self
    end


    def query
      sql = to_query.to_sql
      @composed.connection.exec_query(sql)
    end

    def to_query
      @composed.try(:query) || (@composed = Activecube::Processor::Composer.new(self)).build_query
    end

    def to_sql
      to_query.to_sql
    end

    def column_names measures = self.measures
      (measures + slices + selectors).map(&:required_column_names).flatten.uniq
    end

    def selector_column_names measures = self.measures
      (measures.map(&:selectors) + slices.map(&:selectors) + selectors).flatten.map(&:required_column_names).flatten.uniq
    end

    def reduced other_measures, other_options

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
          Measure.new m.cube, m.key, m.definition, (m.selectors - common_selectors), m.modifications
        }
        reduced_selectors = self.selectors + common_selectors
      end

      unless reduced_measures.detect{|rm| rm.selectors.empty? }
        reduced_selectors += [Selector.or(reduced_measures.map(&:selectors).flatten.uniq)]
      end

      return self if (reduced_measures == self.measures) && (reduced_selectors == self.selectors)

      CubeQuery.new cube, slices, reduced_measures, reduced_selectors, other_options, tables
    end

    def join_fields
      slices.map(&:group_by_columns).flatten.uniq
    end

    def orderings
      options.select{|s| s.kind_of? Ordering}
    end

    private

    def clear_sql
      @composed = nil
    end
  end
end