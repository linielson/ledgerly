# frozen_string_literal: true

module MoneyAttribute
  extend ActiveSupport::Concern

  class_methods do
    def money_attribute(name)
      define_method(name) do
        cents = self["#{name}_cents"]
        code = self["#{name}_currency"]

        return nil if cents.nil? || code.nil?

        Money.new(cents: cents, currency: Currency.fetch(code))
      end

      define_method("#{name}=") do |money|
        unless money.is_a?(Money) || money.nil?
          raise ArgumentError, "#{name} must be a Money, got #{money.inspect} (#{money.class})"
        end

        self["#{name}_cents"] = money&.cents
        self["#{name}_currency"] = money&.currency&.code
      end

      validates name, presence: true
    end
  end
end
