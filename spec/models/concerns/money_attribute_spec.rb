# frozen_string_literal: true

require "rails_helper"

RSpec.describe MoneyAttribute, type: :model do
  let(:brl) { Currency.fetch("BRL") }
  let(:jpy) { Currency.fetch("JPY") }

  # No domain table has money yet (installments and ledger entries come in E4 and E5), so each example creates its
  # own. PostgreSQL runs DDL inside transactions, so the table is rolled back with the rest of the example.
  before do
    ActiveRecord::Base.connection.create_table(:money_attribute_records) do |t|
      t.bigint :amount_cents, null: false
      t.column :amount_currency, "char(3)", null: false
      t.check_constraint "amount_currency ~ '^[A-Z]{3}$'", name: "amount_currency_format"
    end

    # A named class: Active Model needs a name for errors and validations.
    stub_const("MoneyAttributeRecord", Class.new(ApplicationRecord) do
      self.table_name = "money_attribute_records"

      money_attribute :amount
    end)
  end

  describe "writing" do
    it "stores the cents and the currency code in the two columns" do
      record = MoneyAttributeRecord.new(amount: Money.new(1000, brl))

      expect(record).to have_attributes(amount_cents: 1000, amount_currency: "BRL")
    end
  end

  describe "reading" do
    it "builds a Money from the two columns" do
      record = MoneyAttributeRecord.new(amount_cents: 1000, amount_currency: "BRL")

      expect(record.amount).to eq(Money.new(1000, brl))
    end

    it "returns nil when nothing was assigned" do
      expect(MoneyAttributeRecord.new.amount).to be_nil
    end
  end

  describe "round trip" do
    it "reads back the same Money after save and reload" do
      record = MoneyAttributeRecord.create!(amount: Money.new(123_456, brl))

      expect(record.reload.amount).to eq(Money.new(123_456, brl))
    end

    it "keeps a currency without decimals" do
      record = MoneyAttributeRecord.create!(amount: Money.new(1235, jpy))

      expect(record.reload.amount).to eq(Money.new(1235, jpy))
    end

    it "keeps negative amounts" do
      record = MoneyAttributeRecord.create!(amount: Money.new(-500, brl))

      expect(record.reload.amount).to eq(Money.new(-500, brl))
    end

    # 2**53 + 1 is the first integer a Float can't hold; bigint and Integer keep it. The check goes through the
    # reader, not the column, so a Float anywhere on the way back fails it too.
    it "is exact beyond Float precision" do
      record = MoneyAttributeRecord.create!(amount: Money.new(9_007_199_254_740_993, brl))

      expect(record.reload.amount).to eq(Money.new(9_007_199_254_740_993, brl))
    end
  end

  describe "validation" do
    it "is invalid without an amount" do
      record = MoneyAttributeRecord.new

      expect(record).not_to be_valid
      expect(record.errors.of_kind?(:amount, :blank)).to be(true)
    end

    it "is valid with a zero amount" do
      expect(MoneyAttributeRecord.new(amount: Money.zero(brl))).to be_valid
    end

    it "clears both columns when nil is assigned, so the record can't be saved" do
      record = MoneyAttributeRecord.new(amount: Money.new(1000, brl))
      record.amount = nil

      expect(record).to have_attributes(amount_cents: nil, amount_currency: nil)
      expect(record.save).to be(false)
    end
  end

  describe "assigning something that is not a Money" do
    it "raises for a Float" do
      expect { MoneyAttributeRecord.new(amount: 10.5) }
        .to raise_error(ArgumentError, "amount must be a Money, got 10.5 (Float)")
    end

    it "raises for an Integer, which would hide the currency" do
      expect { MoneyAttributeRecord.new(amount: 1000) }
        .to raise_error(ArgumentError, "amount must be a Money, got 1000 (Integer)")
    end

    it "raises for a String, such as a value typed in a form" do
      expect { MoneyAttributeRecord.new(amount: "10,50") }
        .to raise_error(ArgumentError, 'amount must be a Money, got "10,50" (String)')
    end
  end

  # insert_all skips the model, so these show what the database itself enforces.
  describe "database constraints" do
    it "rejects a lowercase currency code" do
      expect { MoneyAttributeRecord.insert_all([ { amount_cents: 1000, amount_currency: "brl" } ]) }
        .to raise_error(ActiveRecord::CheckViolation, /amount_currency_format/)
    end

    it "rejects a currency code shorter than three letters" do
      expect { MoneyAttributeRecord.insert_all([ { amount_cents: 1000, amount_currency: "BR" } ]) }
        .to raise_error(ActiveRecord::CheckViolation, /amount_currency_format/)
    end

    it "rejects missing cents" do
      expect { MoneyAttributeRecord.insert_all([ { amount_cents: nil, amount_currency: "BRL" } ]) }
        .to raise_error(ActiveRecord::NotNullViolation, /amount_cents/)
    end

    it "raises when reading a well-formed code that isn't a known currency" do
      MoneyAttributeRecord.insert_all([ { amount_cents: 1000, amount_currency: "XYZ" } ])

      expect { MoneyAttributeRecord.last.amount }
        .to raise_error(Currency::UnknownCurrencyError, 'Unknown currency: "XYZ"')
    end
  end

  # A payment carries its amount and the gateway's fee (E5): each attribute has its own pair of columns.
  context "with two money attributes on one model" do
    before do
      ActiveRecord::Base.connection.create_table(:money_attribute_payments) do |t|
        t.bigint :amount_cents, null: false
        t.column :amount_currency, "char(3)", null: false
        t.bigint :fee_cents, null: false
        t.column :fee_currency, "char(3)", null: false
        # Same contract as every money table; the constraints themselves are exercised on the first table above.
        t.check_constraint "amount_currency ~ '^[A-Z]{3}$'", name: "payment_amount_currency_format"
        t.check_constraint "fee_currency ~ '^[A-Z]{3}$'", name: "payment_fee_currency_format"
      end

      stub_const("MoneyAttributePayment", Class.new(ApplicationRecord) do
        self.table_name = "money_attribute_payments"

        money_attribute :amount
        money_attribute :fee
      end)
    end

    it "writes each attribute to its own columns" do
      payment = MoneyAttributePayment.new(amount: Money.new(10_000, brl), fee: Money.new(300, brl))

      expect(payment).to have_attributes(amount_cents: 10_000, amount_currency: "BRL", fee_cents: 300, fee_currency: "BRL")
    end

    it "reads each attribute back after save and reload" do
      payment = MoneyAttributePayment.create!(amount: Money.new(10_000, brl), fee: Money.new(300, brl))

      expect(payment.reload).to have_attributes(amount: Money.new(10_000, brl), fee: Money.new(300, brl))
    end

    it "names the attribute in the error for an invalid assignment" do
      expect { MoneyAttributePayment.new(fee: 3.0) }
        .to raise_error(ArgumentError, "fee must be a Money, got 3.0 (Float)")
    end

    it "validates each attribute on its own" do
      payment = MoneyAttributePayment.new(amount: Money.new(10_000, brl))

      expect(payment).not_to be_valid
      expect(payment.errors.attribute_names).to eq([ :fee ])
    end
  end
end
