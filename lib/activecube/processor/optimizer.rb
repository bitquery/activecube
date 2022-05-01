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

        (tables_count == 1 || metrics_count == 0) ? [0] * metrics_count : do_optimize

      end

    end

    private

    def generate_variants vs, metric_i

      return vs if metric_i == metrics_count

      metric_tables = cost_matrix[metric_i].map.with_index do |c, index|
        [index] if c
      end.compact

      vsnew = if metric_i == 0
                metric_tables
              else
                arry = []
                vs.each do |v|
                  metric_tables.each { |newv|
                    arry << (v + newv)
                  }
                end
                arry
              end

      generate_variants vsnew, metric_i + 1

    end

    def cost_for variant
      variant.each_with_index.group_by(&:first).collect do |table_index, arry|
        arry.map(&:second).map { |metric_index| cost_matrix[metric_index][table_index] }.max
      end.sum
    end

    def do_optimize

      # variants = generate_variants [], 0
      variants = gen_reduced_variants
      variant_costs = variants.map { |v| cost_for v }
      variants[variant_costs.each_with_index.min.second]

    end

    def gen_permutations(n, k)
      seq = *(0...n)
      perm = seq.slice(0, k)
      perms = []

      while true
        perms.push perm.dup
        flag = true
        i = 0
        ((k - 1)...-1).step(-1).each do |ii|
          i = ii
          if perm[ii] < n - 1
            flag = false
            break
          end
        end
        return perms if flag

        perm[i] += 1
        ((i + 1)...k).each { |j| perm[j] = 0 }
      end
    end

    def gen_reduced_variants
      # reduce size of cost_matrix deleting duplicates
      uniq_rows = []
      rows_indices = {}
      possible_tables = {}
      cost_matrix.each_with_index do |row, i|
        flag = false

        uniq_rows.each_with_index do |u_row, j|
          if u_row.eql? row
            flag = true
            rows_indices[i] = j
          end
        end

        unless flag
          rows_indices[i] = uniq_rows.length
          possible_tables[i] = Hash[row.map.with_index { |c, index| [index, true] if c }.compact]
          uniq_rows.push(row)
        end
      end

      # generating variants for reduced matrix
      vars = gen_permutations(tables_count, uniq_rows.length)

      # filter possible variants
      vars =  vars.filter do |v|
        v.map.with_index.all? {|t_n, i| possible_tables[i][t_n]}
      end

      # restore variants for full matrix
      vars.map do |variant|
        full_v = Array.new(metrics_count)
        rows_indices.each { |k, v| full_v[k] = variant[v] }

        full_v
      end
    end
  end
end