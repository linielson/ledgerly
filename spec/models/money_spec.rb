# frozen_string_literal: true

require "spec_helper"

require_relative "../../app/models/money"
require_relative "../../app/models/currency"
require "bigdecimal"

RSpec.describe Money do
  let(:brl) { Currency.fetch("BRL") }
  let(:usd) { Currency.fetch("USD") }

  describe "construction" do
    describe ".new" do
      it "exposes the cents and the currency" do
        expect(Money.new(1000, brl)).to have_attributes(cents: 1000, currency: brl)
      end

      it "accepts zero cents" do
        expect(Money.new(0, brl).cents).to eq(0)
      end

      it "accepts negative cents" do
        expect(Money.new(-1000, brl).cents).to eq(-1000)
      end

      context "when the cents are not an Integer" do
        it "raises for a Float" do
          expect { Money.new(10.5, brl) }
            .to raise_error(ArgumentError, "cents must be an Integer, got 10.5 (Float)")
        end

        it "raises for a numeric String" do
          expect { Money.new("1000", brl) }
            .to raise_error(ArgumentError, 'cents must be an Integer, got "1000" (String)')
        end

        it "raises for a whole BigDecimal" do
          expect { Money.new(BigDecimal("10"), brl) }
            .to raise_error(ArgumentError, "cents must be an Integer, got 0.1e2 (BigDecimal)")
        end
      end

      context "when the currency is not a Currency" do
        it "raises for a currency code" do
          expect { Money.new(1000, "BRL") }
            .to raise_error(ArgumentError, 'currency must be a Currency, got "BRL" (String)')
        end

        it "raises for a Hash" do
          expect { Money.new(1000, { code: "BRL", symbol: "R$", exponent: 2 }) }
            .to raise_error(ArgumentError, 'currency must be a Currency, got {code: "BRL", symbol: "R$", exponent: 2} (Hash)')
        end

        it "raises for a lookalike with the same members" do
          # stub_const gives the lookalike a name, so the message is predictable (an anonymous class prints its address)
          stub_const("FakeCurrency", Data.define(:code, :symbol, :exponent))

          expect { Money.new(1000, FakeCurrency.new(code: "BRL", symbol: "R$", exponent: 2)) }
            .to raise_error(ArgumentError, 'currency must be a Currency, got #<data FakeCurrency code="BRL", symbol="R$", exponent=2> (FakeCurrency)')
        end
      end
    end

    describe ".[]" do
      it "exposes the cents and the currency" do
        expect(Money[1000, brl]).to have_attributes(cents: 1000, currency: brl)
      end

      it "validates the cents" do
        expect { Money[10.5, brl] }.to raise_error(ArgumentError, "cents must be an Integer, got 10.5 (Float)")
      end

      it "validates the currency" do
        expect { Money[1000, "BRL"] }.to raise_error(ArgumentError, 'currency must be a Currency, got "BRL" (String)')
      end
    end

    describe "#with" do
      let(:money) { Money.new(1000, brl) }

      it "returns a copy with the new cents and the same currency" do
        expect(money.with(cents: 2500)).to eq(Money.new(2500, brl))
      end

      it "validates the cents" do
        expect { money.with(cents: 10.5) }.to raise_error(ArgumentError, "cents must be an Integer, got 10.5 (Float)")
      end

      it "validates the currency" do
        expect { money.with(currency: "USD") }
          .to raise_error(ArgumentError, 'currency must be a Currency, got "USD" (String)')
      end
    end
  end

  describe "identity and equality" do
    it "is frozen" do
      expect(Money.new(1000, brl)).to be_frozen
    end

    it "is equal to another Money with the same cents and currency" do
      expect(Money.new(1000, brl)).to eq(Money.new(1000, brl))
    end

    it "is not equal to the same cents in another currency" do
      expect(Money.new(1000, brl)).not_to eq(Money.new(1000, usd))
    end

    it "is not equal to other cents in the same currency" do
      expect(Money.new(1000, brl)).not_to eq(Money.new(1001, brl))
    end

    it "is not equal to a bare Integer" do
      expect(Money.new(1000, brl)).not_to eq(1000)
    end

    it "works as a Hash key" do
      labels = { Money.new(1000, brl) => "ten reais" }

      expect(labels[Money.new(1000, brl)]).to eq("ten reais")
    end

    it "does not match a Hash key in another currency" do
      labels = { Money.new(1000, brl) => "ten reais" }

      expect(labels[Money.new(1000, usd)]).to be_nil
    end
  end

  describe ".zero" do
    it "returns zero cents in the given currency" do
      expect(Money.zero(usd)).to eq(Money.new(0, usd))
    end
  end

  describe "arithmetic" do
    describe "#+" do
      it "adds the cents and keeps the currency" do
        expect(Money.new(1234, usd) + Money.new(2345, usd)).to eq(Money.new(3579, usd))
      end

      it "adds a negative amount" do
        expect(Money.new(1000, brl) + Money.new(-250, brl)).to eq(Money.new(750, brl))
      end

      it "returns the same amount when adding zero" do
        expect(Money.new(1000, brl) + Money.zero(brl)).to eq(Money.new(1000, brl))
      end

      it "raises for different currencies, naming the receiver's first" do
        expect { Money.new(1000, usd) + Money.new(1000, brl) }
          .to raise_error(Money::CurrencyMismatchError, "currency mismatch: USD and BRL")
      end

      it "raises for an Integer" do
        expect { Money.new(1000, brl) + 10 }.to raise_error(ArgumentError, "must be a Money: 10 (Integer)")
      end

      it "raises for nil" do
        expect { Money.new(1000, brl) + nil }.to raise_error(ArgumentError, "must be a Money: nil (NilClass)")
      end
    end

    describe "#-" do
      it "subtracts the cents and keeps the currency" do
        expect(Money.new(3579, usd) - Money.new(1234, usd)).to eq(Money.new(2345, usd))
      end

      it "returns a negative amount when subtracting more than there is" do
        expect(Money.new(1000, brl) - Money.new(2000, brl)).to eq(Money.new(-1000, brl))
      end

      it "returns zero when subtracting the same amount" do
        expect(Money.new(1000, brl) - Money.new(1000, brl)).to eq(Money.zero(brl))
      end

      it "raises for different currencies, naming the receiver's first" do
        expect { Money.new(1000, usd) - Money.new(1000, brl) }
          .to raise_error(Money::CurrencyMismatchError, "currency mismatch: USD and BRL")
      end

      it "raises for an Integer" do
        expect { Money.new(1000, brl) - 10 }.to raise_error(ArgumentError, "must be a Money: 10 (Integer)")
      end
    end

    describe "#-@" do
      it "turns a positive amount negative and keeps the currency" do
        expect(-Money.new(1000, usd)).to eq(Money.new(-1000, usd))
      end

      it "turns a negative amount positive" do
        expect(-Money.new(-1000, brl)).to eq(Money.new(1000, brl))
      end

      it "keeps zero as zero" do
        expect(-Money.zero(brl)).to eq(Money.zero(brl))
      end
    end

    describe "#abs" do
      it "turns a negative amount positive and keeps the currency" do
        expect(Money.new(-1000, usd).abs).to eq(Money.new(1000, usd))
      end

      it "keeps a positive amount" do
        expect(Money.new(1000, brl).abs).to eq(Money.new(1000, brl))
      end

      it "keeps zero as zero" do
        expect(Money.zero(brl).abs).to eq(Money.zero(brl))
      end
    end
  end

  describe "predicates" do
    let(:positive) { Money.new(1000, brl) }
    let(:negative) { Money.new(-1000, brl) }
    let(:zero) { Money.zero(brl) }

    describe "#zero?" do
      it "is true for zero" do
        expect(zero).to be_zero
      end

      it "is false for a positive or a negative amount" do
        expect(positive).not_to be_zero
        expect(negative).not_to be_zero
      end
    end

    describe "#positive?" do
      it "is true for a positive amount" do
        expect(positive).to be_positive
      end

      it "is false for zero and for a negative amount" do
        expect(zero).not_to be_positive
        expect(negative).not_to be_positive
      end
    end

    describe "#negative?" do
      it "is true for a negative amount" do
        expect(negative).to be_negative
      end

      it "is false for zero and for a positive amount" do
        expect(zero).not_to be_negative
        expect(positive).not_to be_negative
      end
    end
  end

  describe "comparison" do
    let(:five) { Money.new(500, brl) }
    let(:ten) { Money.new(1000, brl) }
    let(:twenty) { Money.new(2000, brl) }

    describe "#<=>" do
      it "returns -1, 0 or 1 within the same currency" do
        expect(five <=> ten).to eq(-1)
        expect(ten <=> Money.new(1000, brl)).to eq(0)
        expect(twenty <=> ten).to eq(1)
      end

      it "raises for different currencies" do
        expect { ten <=> Money.new(1000, usd) }
          .to raise_error(Money::CurrencyMismatchError, "currency mismatch: BRL and USD")
      end

      it "returns nil for something that is not a Money, as Ruby's <=> protocol expects" do
        expect(ten <=> 1000).to be_nil
      end
    end

    describe "operators from Comparable" do
      it "compares with <, <=, > and >=" do
        expect(five).to be < ten
        expect(ten).to be <= Money.new(1000, brl)
        expect(twenty).to be > ten
        expect(ten).to be >= Money.new(1000, brl)
      end

      it "raises for different currencies" do
        expect { ten < Money.new(2000, usd) }
          .to raise_error(Money::CurrencyMismatchError, "currency mismatch: BRL and USD")
      end

      it "raises Ruby's comparison error for something that is not a Money" do
        expect { ten < 2000 }.to raise_error(ArgumentError, "comparison of Money with 2000 failed")
      end
    end

    # Calls between? directly: RSpec's be_between matcher uses <= and >= instead, and it turns any ArgumentError
    # (CurrencyMismatchError included) into a plain "false".
    describe "#between?" do
      it "is true inside the range, edges included" do
        expect(ten.between?(five, twenty)).to be(true)
        expect(five.between?(five, twenty)).to be(true)
      end

      it "is false outside the range" do
        expect(Money.new(2001, brl).between?(five, twenty)).to be(false)
      end
    end

    describe "#clamp" do
      it "limits the amount to the range" do
        expect(Money.new(5000, brl).clamp(five, twenty)).to eq(twenty)
        expect(Money.new(100, brl).clamp(five, twenty)).to eq(five)
        expect(ten.clamp(five, twenty)).to eq(ten)
      end
    end

    describe "sorting" do
      it "sorts and finds the max and min of a list" do
        amounts = [ twenty, five, ten ]

        expect(amounts.sort).to eq([ five, ten, twenty ])
        expect(amounts.max).to eq(twenty)
        expect(amounts.min).to eq(five)
      end
    end

    describe "#==" do
      # Comparable brings its own == built on <=>, which would raise CurrencyMismatchError here.
      it "returns false for different currencies instead of raising" do
        expect(ten == Money.new(1000, usd)).to be(false)
      end
    end
  end

  describe "#allocate" do
    let(:jpy) { Currency.fetch("JPY") }

    def cents_of(parts) = parts.map(&:cents)

    context "with a number of equal parts" do
      it "gives the remainder cents to the first parts" do
        expect(cents_of(Money.new(10_000, brl).allocate(3))).to eq([ 3334, 3333, 3333 ])
      end

      it "splits evenly when there is no remainder" do
        expect(cents_of(Money.new(9000, brl).allocate(3))).to eq([ 3000, 3000, 3000 ])
      end

      it "returns the whole amount, in an array, for one part" do
        expect(Money.new(10_000, brl).allocate(1)).to eq([ Money.new(10_000, brl) ])
      end

      it "gives zero to the last parts when there are fewer cents than parts" do
        expect(cents_of(Money.new(2, brl).allocate(3))).to eq([ 1, 1, 0 ])
      end

      it "splits zero into zeros" do
        expect(Money.zero(brl).allocate(3)).to eq([ Money.zero(brl) ] * 3)
      end

      it "mirrors a positive split for a negative amount" do
        expect(cents_of(Money.new(-10_000, brl).allocate(3))).to eq([ -3334, -3333, -3333 ])
      end

      it "works in minor units for a currency without decimals, keeping the currency" do
        expect(Money.new(100, jpy).allocate(3)).to eq([ Money.new(34, jpy), Money.new(33, jpy), Money.new(33, jpy) ])
      end
    end

    context "with ratios" do
      it "splits in proportion to the ratios" do
        expect(cents_of(Money.new(10_000, brl).allocate([ 1, 2 ]))).to eq([ 3334, 6666 ])
      end

      it "gives the same result for equal ratios as for the same number of parts" do
        money = Money.new(10_000, brl)

        expect(money.allocate([ 1, 1, 1 ])).to eq(money.allocate(3))
      end

      it "gives the remainder cents to the first parts, whatever their ratio" do
        # Exact shares are 6, 1.5 and 1.5: the floors add up to 8, and the 1 cent left goes to the first part.
        expect(cents_of(Money.new(9, brl).allocate([ 4, 1, 1 ]))).to eq([ 7, 1, 1 ])
      end

      it "mirrors a positive split for a negative amount" do
        expect(cents_of(Money.new(-10_000, brl).allocate([ 1, 2 ]))).to eq([ -3334, -6666 ])
      end
    end

    context "when the number of parts is not a positive Integer" do
      it "raises for zero" do
        expect { Money.new(10_000, brl).allocate(0) }
          .to raise_error(ArgumentError, "parts must be a positive Integer, got 0 (Integer)")
      end

      it "raises for a negative number" do
        expect { Money.new(10_000, brl).allocate(-1) }
          .to raise_error(ArgumentError, "parts must be a positive Integer, got -1 (Integer)")
      end

      it "raises for a Float" do
        expect { Money.new(10_000, brl).allocate(2.5) }
          .to raise_error(ArgumentError, "parts must be a positive Integer, got 2.5 (Float)")
      end

      it "raises for a numeric String" do
        expect { Money.new(10_000, brl).allocate("3") }
          .to raise_error(ArgumentError, 'parts must be a positive Integer, got "3" (String)')
      end

      it "raises for nil" do
        expect { Money.new(10_000, brl).allocate(nil) }
          .to raise_error(ArgumentError, "parts must be a positive Integer, got nil (NilClass)")
      end
    end

    context "when the ratios are not all positive Integers" do
      it "raises for an empty list" do
        expect { Money.new(10_000, brl).allocate([]) }
          .to raise_error(ArgumentError, "ratios must be a non-empty Array of positive Integers, got [] (Array)")
      end

      # A zero ratio first is the case that matters: the remainder goes to the first parts, so it would get a cent.
      it "raises for a zero ratio" do
        expect { Money.new(101, brl).allocate([ 0, 1, 1 ]) }
          .to raise_error(ArgumentError, "ratios must be a non-empty Array of positive Integers, got [0, 1, 1] (Array)")
      end

      it "raises for a negative ratio" do
        expect { Money.new(10_000, brl).allocate([ 1, -1 ]) }
          .to raise_error(ArgumentError, "ratios must be a non-empty Array of positive Integers, got [1, -1] (Array)")
      end

      it "raises for a Float ratio" do
        expect { Money.new(10_000, brl).allocate([ 1, 0.5 ]) }
          .to raise_error(ArgumentError, "ratios must be a non-empty Array of positive Integers, got [1, 0.5] (Array)")
      end
    end

    # Random cases from RSpec's seed: rerun a failure with `rspec --seed <seed>`, which RSpec prints after each run.
    context "properties" do
      let(:random) { Random.new(RSpec.configuration.seed) }

      it "splits into equal parts that add up to the original, at most one cent apart, larger parts first" do
        500.times do
          money = Money.new(random.rand(-1_000_000..1_000_000), brl)
          count = random.rand(1..12)
          parts = money.allocate(count)
          sizes = parts.map { |part| part.cents.abs }
          example = "#{money.cents} cents in #{count} parts"

          expect(parts.sum(Money.zero(brl))).to eq(money), "sum differs for #{example}"
          expect(parts.size).to eq(count), "wrong number of parts for #{example}"
          expect(parts.map(&:currency).uniq).to eq([ brl ]), "currency changed for #{example}"
          expect(sizes.max - sizes.min).to be <= 1, "parts more than one cent apart for #{example}"
          expect(sizes).to eq(sizes.sort.reverse), "a larger part comes after a smaller one for #{example}"
        end
      end

      it "splits by ratios into parts that add up to the original, each within one cent of its exact share" do
        500.times do
          money = Money.new(random.rand(-1_000_000..1_000_000), brl)
          ratios = Array.new(random.rand(1..6)) { random.rand(1..100) }
          parts = money.allocate(ratios)
          total_ratio = ratios.sum
          example = "#{money.cents} cents by #{ratios}"

          expect(parts.sum(Money.zero(brl))).to eq(money), "sum differs for #{example}"
          expect(parts.size).to eq(ratios.size), "wrong number of parts for #{example}"
          expect(parts.map(&:currency).uniq).to eq([ brl ]), "currency changed for #{example}"
          parts.zip(ratios).each do |part, ratio|
            # part / money == ratio / total_ratio, give or take one cent, without dividing (so no rounding here)
            expect((part.cents * total_ratio - money.cents * ratio).abs)
              .to be <= total_ratio, "part #{part.cents} is more than one cent off its share for #{example}"
          end
        end
      end
    end
  end
end
