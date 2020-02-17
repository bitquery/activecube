module Test
  class TransfersCurrency < ApplicationRecord
    self.table_name = 'transfers_currency'

    index 'currency_id', cardinality: 4

  end
end
