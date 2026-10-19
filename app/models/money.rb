# frozen_string_literal: true

require "bigdecimal"

class Money < Data.define(:cents, :currency)
  include Comparable

  class CurrencyMismatchError < ArgumentError; end

  SUPPORTED_LOCALES = {
    "pt-BR" => { thousands: ".", decimal: ",", space: " " },
    "en" => { thousands: ",", decimal: ".", space: "" }
  }.freeze

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

  def allocate(parts_or_ratios)
    return abs.allocate(parts_or_ratios).map { |part| -part } if negative?

    ratios = if parts_or_ratios.is_a?(Array)
      ensure_ratios!(parts_or_ratios)
      parts_or_ratios
    else
      ensure_positive_parts!(parts_or_ratios)
      Array.new(parts_or_ratios, 1)
    end

    total_ratio = ratios.sum
    shares = ratios.map { |ratio| cents * ratio / total_ratio }

    remainder = cents - shares.sum
    remainder.times { |i| shares[i] += 1 }

    shares.map { |part_cents| Money.new(part_cents, currency) }
  end

  def formatted(locale:)
    return "-#{abs.formatted(locale:)}" if negative?

    rules = SUPPORTED_LOCALES.fetch(locale) { raise ArgumentError, "Unknown locale: #{locale.inspect}" }

    units, minor = cents.divmod(10**currency.exponent).map(&:to_s)
    # Inserts the separator before every group of three digits, counting from the right
    units = units.gsub(/(\d)(?=(\d{3})+(?!\d))/, "\\1#{rules[:thousands]}")

    decimal_part = currency.exponent.zero? ? "" : "#{rules[:decimal]}#{minor.rjust(currency.exponent, "0")}"
    "#{currency.symbol}#{rules[:space]}#{units}#{decimal_part}"
  end

  def *(multiplier)
    ensure_exact_multiplier!(multiplier)

    rounded_cents = (cents * multiplier).round(half: :even).to_i
    with(cents: rounded_cents)
  end

  private

    def ensure_money!(other)
      raise ArgumentError, "must be a Money: #{other.inspect} (#{other.class})" unless other.is_a?(Money)
    end

    def ensure_same_currency!(other)
      raise CurrencyMismatchError, "currency mismatch: #{currency.code} and #{other.currency.code}" unless currency == other.currency
    end

    def ensure_positive_parts!(number_of_parts)
      return if number_of_parts.is_a?(Integer) && number_of_parts.positive?

      raise ArgumentError, "parts must be a positive Integer, got #{number_of_parts.inspect} (#{number_of_parts.class})"
    end

    def ensure_ratios!(ratios)
      return if ratios.is_a?(Array) && !ratios.empty? && ratios.all? { |ratio| ratio.is_a?(Integer) && ratio.positive? }

      raise ArgumentError, "ratios must be a non-empty Array of positive Integers, got #{ratios.inspect} (#{ratios.class})"
    end

    def ensure_exact_multiplier!(multiplier)
      return if [ Integer, BigDecimal, Rational ].any? { |type| multiplier.is_a?(type) }

      message = "multiplier must be an Integer, BigDecimal or Rational, got #{multiplier.inspect} (#{multiplier.class})"
      message += ". Use BigDecimal(#{multiplier.to_s.inspect}) instead" if multiplier.is_a?(Float)
      raise ArgumentError, message
    end
end
