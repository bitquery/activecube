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

        tables_count==1 ? [0]*metrics_count : do_optimize

       end


    end

    private

    def do_optimize

      @tables_by_metrics = []

      # sort metrics from low min cost to higher min costs ( by all applicable tables )
      sort_metrics

      # fill initial @tables_by_metrics by selecting tables with minimum cost for metrics.
      # If there are more than one table with this minimum cost, then select already selected table with maximum cost
      select_min_cost_by_metric

      # make iterations over @tables_by_metrics ( max MAX_ITERATIONS)
      iterates

      @tables_by_metrics
    end

    def sort_metrics
      @metrics_index_sorted = (0...metrics_count).sort_by{|m_i| cost_matrix[m_i].compact.min || UNLIM_COST }
    end

    def select_min_cost_by_metric

      @metrics_index_sorted.collect do |m_i|

        table_index_cost = (0...tables_count).map{|c_i| [c_i,
                                                        cost_matrix[m_i][c_i] || UNLIM_COST,
                                                        (@tables_by_metrics.include?(c_i) ? -cost_matrix[@tables_by_metrics.index(c_i)][c_i] : 0)
        ]}.sort_by(&:third).sort_by(&:second)

        @tables_by_metrics[m_i] = table_index_cost.first.first

      end
    end

    def iterates

      steps = [@tables_by_metrics]

      (1..MAX_ITERATIONS).each do |iteration|

        step = []
        prev_step = steps.last

        prev_step.each_with_index {|c_i, m_i|

          table_included_times = prev_step.select{|c| c==c_i }.count
          old_cost = cost_matrix[m_i][c_i]
          new_c_i = (0...tables_count).detect{|c_n|
            new_cost = cost_matrix[m_i][c_n]
            next if c_i==c_n || new_cost.nil?
            new_table_included_times = prev_step.select{|c| c==c_n }.count

            if old_cost.nil?
              # if we have non indexed table now
              true
            elsif table_included_times>1
              if new_table_included_times>0
                # table to used table if
                # cost now > new cost
                old_cost > new_cost
              else
                # table to unused table if
                # cost now > new cost + max other cost in table now
                old_cost > new_cost + ( prev_step.select.with_index{|c,i| c==c_i && i!=m_i }.map{|c| cost_matrix[m_i][c]}.max || UNLIM_COST )
              end
            else
              if new_table_included_times>0
                # unused table to table if
                # new cost <  cost now + max other cost in new table
                old_cost > new_cost - ( prev_step.select{|c| c==c_n }.map{|c| cost_matrix[m_i][c]}.max || UNLIM_COST )
              else
                # unused to unused
                # cost now > new cost
                old_cost > new_cost
              end
            end

          }

          step << (new_c_i || c_i)

        }

        break if steps.include? step
        steps << step
      end

      @tables_by_metrics = steps.last

    end

  end

end