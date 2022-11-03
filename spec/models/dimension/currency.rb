module Dimension
  class Currency < Activecube::Dimension
    column 'currency_id'
    identity_column 'currency_id'

    field 'symbol', "dictGetString('currency', 'symbol', toUInt64(currency_id))"
    field 'name', "dictGetString('currency', 'name', toUInt64(currency_id))"
    field 'token_id', "dictGetUInt32('currency', 'token_id', toUInt64(currency_id))"
    field 'token_type', "dictGetString('currency', 'token_type', toUInt64(currency_id))"
    field 'decimals', "dictGetUInt8('currency', 'decimals', toUInt64(currency_id))"
    field 'address', "dictGetString('currency', 'address', toUInt64(currency_id))"
  end
end
