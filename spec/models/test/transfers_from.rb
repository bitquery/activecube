module Test
  class TransfersFrom < ApplicationRecord
    self.table_name = 'transfers_from'

    index 'transfer_from_bin', cardinality: 10

  end
end
