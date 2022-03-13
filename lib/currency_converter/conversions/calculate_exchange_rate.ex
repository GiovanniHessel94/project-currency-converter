defmodule CurrencyConverter.Conversions.CalculateExchangeRate do
  @moduledoc """
    Calculate exchange rate module.

    Responsible for calculating the exchange rate between two
    currencies. It does it dividing source base exchange rate
    by destination base exchange rate.
  """

  alias CurrencyConverter.{Decimals.SetContextPrecision, Error}

  @invalid_params_message "invalid params to calculate the exchange rate"

  def call(
        %Decimal{sign: 1} = source_base_exchange_rate,
        %Decimal{sign: 1} = destination_base_exchange_rate
      ) do
    SetContextPrecision.call()

    exchange_rate =
      destination_base_exchange_rate
      |> Decimal.div(source_base_exchange_rate)
      |> Decimal.round(5)

    {:ok, exchange_rate}
  end

  def call(
        _source_base_exchange_rate,
        _destination_base_exchange_rate
      ),
      do: {:error, Error.build(:unprocessable_entity, @invalid_params_message)}
end
