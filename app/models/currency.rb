# frozen_string_literal: true

# Data freezes the instance, not its members: the literal strings below must be frozen too.
class Currency < Data.define(:code, :symbol, :exponent)
  class UnknownCurrencyError < ArgumentError; end

  CURRENCIES = {
    "BRL" => new(code: "BRL", symbol: "R$", exponent: 2),
    "USD" => new(code: "USD", symbol: "$", exponent: 2),
    "JPY" => new(code: "JPY", symbol: "¥", exponent: 0),
    "BHD" => new(code: "BHD", symbol: "BD", exponent: 3) # BHD uses "BD", the Latin-script symbol
  }.freeze

  def self.fetch(code)
    key = code.to_s.upcase if code.is_a?(String) || code.is_a?(Symbol)
    CURRENCIES.fetch(key) { raise UnknownCurrencyError, "Unknown currency: #{code.inspect}" }
  end

  def clone(freeze: nil) = self

  def dup = self

  private :with

  private_class_method :new, :[]
end
