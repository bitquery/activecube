module Test
  class TransferFromSelector < Activecube::Selector

    include QueryHelper

    column 'transfer_from_bin'

    def expression arel_table, selector, _cube_query
      op = selector.operator
      op.expression arel_table[self.class.column_name], unhex_bin(op.argument)
    end

  end
end