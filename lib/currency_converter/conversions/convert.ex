defmodule CurrencyConverter.Conversions.Convert do
  @moduledoc """
    Convert module.

    Responsible for converting the amount from source currency
    to destination currency based on the received exchange rates.
  """

  alias CurrencyConverter.{
    Constants.Currencies,
    Conversion,
    Conversions.CalculateDestinationAmount,
    Conversions.CalculateExchangeRate,
    Error,
    ExchangeRates
  }

  alias CurrencyConverter.Decimals.Create, as: CreateDecimal

  @available_currencies Currencies.get_available_currencies()

  @invalid_params_message "invalid source amount, source currency or destination currency"
  @missing_exchange_rates_message "can't fetch exchange rates"

  def call(
        %ExchangeRates{} = exchange_struct,
        %Conversion{
          source_amount: %Decimal{} = source_amount,
          source_currency: source_currency,
          destination_currency: destination_currency
        } = conversion
      )
      when source_currency in @available_currencies and
             destination_currency in @available_currencies do
    with {
           :ok,
           currencies_base_exchange_rates
         } <- build_currencies_base_exchange_rates(exchange_struct, conversion),
         {:ok, exchange_rate} <- call_calculate_exchange_rate(currencies_base_exchange_rates),
         {
           :ok,
           destination_amount
         } <- CalculateDestinationAmount.call(exchange_rate, source_amount) do
      {:ok, build_conversion_attrs(exchange_rate, destination_amount)}
    end
  end

  def call(
        _exchange_rates,
        _conversion
      ),
      do: {:error, Error.build(:unprocessable_entity, @invalid_params_message)}

  defp build_currencies_base_exchange_rates(
         %ExchangeRates{
           exchange_rates: exchange_rates
         },
         %Conversion{
           source_currency: source_currency,
           destination_currency: destination_currency
         }
       )
       when is_map(exchange_rates) do
    with {
           :ok,
           source_currency_base_exchange_rate
         } <- build_currency_base_exchange_rate(exchange_rates, source_currency),
         {
           :ok,
           destination_currency_base_exchange_rate
         } <- build_currency_base_exchange_rate(exchange_rates, destination_currency) do
      {:ok, {source_currency_base_exchange_rate, destination_currency_base_exchange_rate}}
    end
  end

  defp build_currencies_base_exchange_rates(
         _exchange_struct,
         _conversion
       ),
       do: {:error, Error.build(:unprocessable_entity, @missing_exchange_rates_message)}

  defp call_calculate_exchange_rate(
         {source_currency_base_exchange_rate, destination_currency_base_exchange_rate}
       ),
       do:
         CalculateExchangeRate.call(
           source_currency_base_exchange_rate,
           destination_currency_base_exchange_rate
         )

  defp build_conversion_attrs(exchange_rate, destination_amount) do
    %{
      exchange_rate: exchange_rate,
      destination_amount: destination_amount,
      processed_at: DateTime.utc_now()
    }
  end

  defp build_currency_base_exchange_rate(exchange_rates, currency),
    do:
      exchange_rates
      |> Map.get(currency)
      |> transform_currency_exchange_rate(currency)

  defp transform_currency_exchange_rate(nil, currency),
    do: {
      :error,
      Error.build(
        :unprocessable_entity,
        "can't fetch the exchange rate of the \"#{currency}\" currency"
      )
    }

  defp transform_currency_exchange_rate(
         currency_exchange_rate,
         _currency
       ),
       do: CreateDecimal.call(currency_exchange_rate)
end
