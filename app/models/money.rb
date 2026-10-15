# frozen_string_literal: true

class Money < Data.define(:cents, :currency)
  include Comparable

  class CurrencyMismatchError < ArgumentError; end

  def initialize(cents:, currency:)
    raise ArgumentError, "cents must be an Integer, got #{cents.inspect} (#{cents.class})" unless cents.is_a?(Integer)
    raise ArgumentError, "currency must be a Currency, got #{currency.inspect} (#{currency.class})" unless currency.is_a?(Currency)

    super(cents:, currency:)
  end

  def self.zero(currency)
    new(0, currency)
  end

  def +(other)
    ensure_money!(other)
    ensure_same_currency!(other)

    Money.new(cents + other.cents, currency)
  end

  def -(other)
    ensure_money!(other)
    ensure_same_currency!(other)

    Money.new(cents - other.cents, currency)
  end

  def -@
    Money.new(-cents, currency)
  end

  def abs
    Money.new(cents.abs, currency)
  end

  def zero?
    cents.zero?
  end

  def positive?
    cents.positive?
  end

  def negative?
    cents.negative?
  end

  def <=>(other)
    return nil unless other.is_a?(Money)
    ensure_same_currency!(other)

    cents <=> other.cents
  end

  def ==(other) = other.is_a?(Money) && currency == other.currency && cents == other.cents

private

  def ensure_money!(other)
    raise ArgumentError, "must be a Money: #{other.inspect} (#{other.class})" unless other.is_a?(Money)
  end

  def ensure_same_currency!(other)
    raise CurrencyMismatchError, "currency mismatch: #{currency.code} and #{other.currency.code}" unless currency == other.currency
  end
end
