defmodule CurrencyConverter.ExternalServices.ExchangeRatesApi.Client do
  @moduledoc """
    Exchange rates api client.

    Responsible for grouping all the operations
    performed in the exchange rates api.
  """

  alias CurrencyConverter.{ExternalServices.ExchangeRatesApi, Utils}
  alias ExchangeRatesApi.{Behavior, Requests.FetchExchangeRates}

  @behaviour Behavior

  @impl true
  def fetch_exchange_rates(destination_currency),
    do: FetchExchangeRates.call(get_base_url(), destination_currency)

  def get_base_url, do: Utils.get_env("EXCHANGE_RATES_API_BASE_URL")
end
