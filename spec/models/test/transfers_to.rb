module Test
  class TransfersTo < ApplicationRecord
    self.table_name = 'transfers_to'

    index 'transfer_to_bin', cardinality: 10
  end
end
