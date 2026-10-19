# 0013. Money is formatted by an explicit locale with integer arithmetic

- **Status:** Accepted
- **Date:** 2026-10-16
- **Ticket:** T-104 (#26)

## Context

[ADR-0002](0002-money-as-integer-minor-units.md) says formatting uses integer arithmetic only. The usual shortcut,
`cents / 100.0` or `to_f`, breaks that: a Float can't hold most decimals exactly, and above 2⁵³ it loses whole digits
(9007199254740993 cents become `...409,92` instead of `...409,93`). Showing money also mixes two independent things:
the **currency** knows its symbol and number of decimals (R$, 2; ¥, 0; BD, 3), while the **locale** knows the
separators and where the symbol goes (`R$ 1.234,56` in pt-BR, `$1,234.56` in en).

Options considered for where the locale rules live:

- **Rails I18n with `number_to_currency`:** standard and translatable, but it lives in the view layer, goes through
  BigDecimal with its own rounding options, and would make the Money spec load Rails.
- **A small table inside `Money`:** two locales, pure Ruby, and integer arithmetic we own and test.

## Decision

- `Money#formatted(locale:)` returns the display string. It is not `format`, which would shadow `Kernel#format` inside
  the class, nor `to_s`, which logs and string interpolation call without a locale.
- The locale is a **required** keyword with no default. The tenant decides it (E2), and a hidden default would show
  pt-BR formatting to an English-speaking customer without anyone noticing. An unknown locale raises `ArgumentError`.
- Supported locales live in `Money::SUPPORTED_LOCALES`: `"pt-BR"` (`.` for thousands, `,` for decimals, a space after
  the symbol) and `"en"` (`,`, `.`, no space).
- The amount is split with `divmod(10 ** exponent)`. Thousands are grouped on the digit string and decimals are padded
  with zeros. A currency without decimals shows no decimal separator.
- Negative amounts put the minus sign before the symbol in every locale: `-R$ 1.234,56`, `-$1,234.56`.

## Consequences

- Formatting is exact for any amount the database can hold. A spec with 2⁵³ + 1 cents guards it, and it is the only
  spec that fails if someone switches to Float.
- Adding a locale is one row in the table plus its specs.
- Full CLDR rules are out of scope: English would write `BHD 1,234.567`, while this table gives `BD1,234.567`.
  Accounting-style parentheses and amounts in words are out of scope too.
- Revisit when the app needs more than a few locales or translated currency names: move the rules to Rails I18n,
  keeping the integer split, in a new ADR.
