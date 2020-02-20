module Test
  class DateSelector < Activecube::Selector

    include QueryHelper

    column 'tx_date'

  end
end