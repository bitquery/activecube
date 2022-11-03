module QueryHelper
  def dict_currency_divider(expression)
    "dictGet('currency', 'divider', toUInt64(#{expression}))"
  end

  def unhex_bin(string)
    if string.is_a? Array
      string.map { |s| unhex_bin s }
    elsif string.is_a? String
      hex = string.downcase.delete_prefix('0x')
      Arel.sql("unhex('#{hex}')")
    end
  end
end
