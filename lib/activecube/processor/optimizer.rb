module Activecube::Processor

  class Optimizer

    UNLIM_COST = 9999
    MAX_ITERATIONS = 3

    attr_reader :tables_count, :metrics_count, :cost_matrix
    def initialize cost_matrix
      @cost_matrix = cost_matrix
      @cache = ActiveSupport::Cache::MemoryStore.new
    end

    def optimize

      @cache.fetch(cost_matrix, expires_in: 12.hours) do

        @tables_count = cost_matrix.map(&:count).max
        @metrics_count = cost_matrix.count

        (tables_count==1 || metrics_count==0) ? [0]*metrics_count : do_optimize

       end


    end

    private

    def generate_variants vs, metric_i

      return vs if metric_i==metrics_count

      metric_tables = cost_matrix[metric_i].map.with_index do |c, index|
        [index] if c
      end.compact

      vsnew = if metric_i==0
         metric_tables
      else
        arry = []
        vs.each do |v|
          metric_tables.each{|newv|
            arry << (v + newv)
          }
        end
        arry
      end

      generate_variants vsnew, metric_i+1

    end

    def cost_for variant
      variant.each_with_index.group_by(&:first).collect do |table_index, arry|
        arry.map(&:second).map{|metric_index| cost_matrix[metric_index][table_index] }.max
      end.sum
    end

    def do_optimize

      variants = generate_variants [], 0
      variant_costs = variants.map{|v| cost_for v}
      variants[variant_costs.each_with_index.min.second]

    end

  end

end