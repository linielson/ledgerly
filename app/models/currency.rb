class Currency < Data.define(:code, :symbol, :exponent)
  class UnknownCurrencyError < ArgumentError; end

  CURRENCIES = {
    "BRL" => new(code: "BRL", symbol: "R$", exponent: 2),
    "USD" => new(code: "USD", symbol: "$", exponent: 2),
    "JPY" => new(code: "JPY", symbol: "¥", exponent: 0),
    "BHD" => new(code: "BHD", symbol: "BD", exponent: 3) # BHD uses "BD", the Latin-script symbol
  }.freeze

  def self.fetch(code)
    CURRENCIES.fetch(code.to_s.upcase) { raise UnknownCurrencyError, "Unknown currency: #{code.inspect}" }
  end

  def clone(freeze: nil) = self

  def dup = self

  private :with

  private_class_method :new, :[]
end
