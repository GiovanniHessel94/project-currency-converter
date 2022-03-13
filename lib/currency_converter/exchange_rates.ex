defmodule CurrencyConverter.ExchangeRates do
  @moduledoc """
    Exchange rates module.

    Struct that represents an exchange rate with
    the base currency and a timestamp.
  """

  @type exchange_rates :: %__MODULE__{
          base: String.t(),
          exchange_rates: map(),
          timestamp: Integer.t()
        }

  @keys [
    :base,
    :exchange_rates,
    :timestamp
  ]

  @enforce_keys @keys

  defstruct @keys

  def build(base, exchange_rates, timestamp) do
    %__MODULE__{
      base: base,
      exchange_rates: exchange_rates,
      timestamp: timestamp
    }
  end
end
