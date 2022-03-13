defmodule CurrencyConverter.ExchangeRatesApi.Requests.FetchExchangeRates.ResponseBuilder do
  @moduledoc """
    Fetch exchange rates response build module.

    Responsible building the response that will be returned
    by sent the fetch exchange rates operation.
  """

  alias CurrencyConverter.{Error, ExchangeRates}

  @generic_error_message "an error occurred while processing the exchange rates response"

  def call(%{
        "base" => base,
        "rates" => exchange_rates,
        "timestamp" => timestamp
      }),
      do: {:ok, ExchangeRates.build(base, exchange_rates, timestamp)}

  def call(_response_body),
    do: {:error, Error.build(:unprocessable_entity, @generic_error_message)}
end
