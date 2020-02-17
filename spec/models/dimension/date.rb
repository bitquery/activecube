module Dimension
  class Date < Activecube::Dimension

    DEFAULT_FORMAT = '%Y-%m-%d'

    column 'tx_date'

    field 'month', 'toMonth(tx_date)'
    field 'year', 'toYear(tx_date)'
    field 'dayOfMonth', 'toDayOfMonth(tx_date)'
    field 'dayOfWeek', 'toDayOfWeek(tx_date)'

    field 'date', {
        format: ->(string){ "formatDateTime(tx_date,'#{ string || DEFAULT_FORMAT}')" },
        default: "formatDateTime(tx_date,'#{ DEFAULT_FORMAT}')"
    }

  end
end