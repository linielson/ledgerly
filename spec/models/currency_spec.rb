require "spec_helper"

require_relative "../../app/models/currency"

RSpec.describe Currency do
  describe ".fetch" do
    it "returns BRL with symbol R$ and 2 decimal places" do
      expect(Currency.fetch("BRL")).to have_attributes(code: "BRL", symbol: "R$", exponent: 2)
    end

    it "returns USD with symbol $ and 2 decimal places" do
      expect(Currency.fetch("USD")).to have_attributes(code: "USD", symbol: "$", exponent: 2)
    end

    it "returns JPY with symbol ¥ and no decimal places" do
      expect(Currency.fetch("JPY")).to have_attributes(code: "JPY", symbol: "¥", exponent: 0)
    end

    it "returns BHD with symbol BD and 3 decimal places" do
      expect(Currency.fetch("BHD")).to have_attributes(code: "BHD", symbol: "BD", exponent: 3)
    end

    it "ignores the case of the code" do
      expect(Currency.fetch("brl")).to have_attributes(code: "BRL", symbol: "R$", exponent: 2)
      expect(Currency.fetch("usD")).to have_attributes(code: "USD", symbol: "$", exponent: 2)
      expect(Currency.fetch("Jpy")).to have_attributes(code: "JPY", symbol: "¥", exponent: 0)
      expect(Currency.fetch("bHd")).to have_attributes(code: "BHD", symbol: "BD", exponent: 3)
    end

    it "accepts the code as a Ruby Symbol" do
      expect(Currency.fetch(:brl)).to have_attributes(code: "BRL", symbol: "R$", exponent: 2)
      expect(Currency.fetch(:usd)).to have_attributes(code: "USD", symbol: "$", exponent: 2)
      expect(Currency.fetch(:JPY)).to have_attributes(code: "JPY", symbol: "¥", exponent: 0)
      expect(Currency.fetch(:BHD)).to have_attributes(code: "BHD", symbol: "BD", exponent: 3)
    end

    context "when the code is not registered" do
      it "raises UnknownCurrencyError naming the code" do
        expect { Currency.fetch("ERR") }.to raise_error(Currency::UnknownCurrencyError, 'Unknown currency: "ERR"')
      end

      it "raises for nil instead of NoMethodError" do
        expect { Currency.fetch(nil) }.to raise_error(Currency::UnknownCurrencyError, "Unknown currency: nil")
      end

      it "does not strip surrounding whitespace" do
        expect { Currency.fetch(" BRL ") }.to raise_error(Currency::UnknownCurrencyError, 'Unknown currency: " BRL "')
        expect { Currency.fetch(" BRL") }.to raise_error(Currency::UnknownCurrencyError, 'Unknown currency: " BRL"')
        expect { Currency.fetch("BRL ") }.to raise_error(Currency::UnknownCurrencyError, 'Unknown currency: "BRL "')
      end

      it "raises for a non-string code" do
        expect { Currency.fetch(42) }.to raise_error(Currency::UnknownCurrencyError, "Unknown currency: 42")
      end
    end
  end

  describe "identity and equality" do
    it "returns the same object for a code however it is written" do
      brl = Currency.fetch("BRL")

      expect(Currency.fetch("brl")).to be(brl)
      expect(Currency.fetch(:BRL)).to be(brl)
    end

    it "is equal to the same currency and different from others" do
      expect(Currency.fetch("BRL")).to eq(Currency.fetch(:brl))
      expect(Currency.fetch("BRL")).not_to eq(Currency.fetch("USD"))
    end

    it "works as a Hash key" do
      names = { Currency.fetch("BRL") => "real" }

      expect(names[Currency.fetch(:brl)]).to eq("real")
    end

    it "is frozen" do
      expect(Currency.fetch("BRL")).to be_frozen
    end

    it "duplicated currency is the same as the original one" do
      brl = Currency.fetch("BRL")
      expect(brl.dup).to be(brl)
    end

    it "cloned currency is the same as the original one" do
      brl = Currency.fetch("BRL")
      expect(brl.clone).to be(brl)
    end
  end

  describe "construction" do
    it "can't be created with .new outside the registry" do
      expect { Currency.new(code: "BRL", symbol: "R$", exponent: 3) }.to raise_error(NoMethodError)
    end

    it "can't be created with .[] outside the registry" do
      expect { Currency[code: "BRL", symbol: "R$", exponent: 3] }.to raise_error(NoMethodError)
    end

    it "can't be copied with different attributes through #with" do
      expect { Currency.fetch("BRL").with(exponent: 3) }.to raise_error(NoMethodError)
    end
  end
end
