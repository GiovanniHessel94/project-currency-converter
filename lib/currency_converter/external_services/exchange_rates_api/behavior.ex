defmodule CurrencyConverter.ExternalServices.ExchangeRatesApi.Behavior do
  @moduledoc """
    Exchange rates api client behavior.

    Responsible for defining the behaviors of the exchange rates api client.
  """

  alias CurrencyConverter.{Error, ExchangeRates}

  @callback fetch_exchange_rates(String.t()) :: {:ok, ExchangeRates.t()} | {:error, Error.t()}
end
