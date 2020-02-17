module Test
  class TransfersCube < Activecube::Base

    table TransfersCurrency
    table TransfersFrom
    table TransfersTo

    dimension date: Dimension::Date,
              currency: Dimension::Currency

    metric amount: Metric::Amount,
           count: Metric::Count

    selector currency: CurrencySelector,
             transfer_from: TransferFromSelector,
             transfer_to: TransferToSelector

  end
end