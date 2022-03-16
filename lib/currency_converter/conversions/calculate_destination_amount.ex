defmodule CurrencyConverter.Conversions.CalculateDestinationAmount do
  @moduledoc """
    Calculate destination amount module.

    Responsible for calculating the destination amount by multiplying
    exchange rate by source amount. It also validates if the operation
    results are within the decimal precision.
  """

  alias CurrencyConverter.{Decimals.SetContextPrecision, Error}

  @invalid_params_message "invalid params to calculate the destination amount"
  @results_cant_be_trusted_message "this operations exceeds the decimal precision so results can't be trusted"

  def call(
        %Decimal{sign: 1} = exchange_rate,
        %Decimal{sign: 1} = source_amount
      ) do
    SetContextPrecision.call()

    exchange_rate
    |> Decimal.mult(source_amount)
    |> Decimal.round(5)
    |> validate_operation()
  end

  def call(
        _exchange_rate,
        _source_amount
      ),
      do: {:error, Error.build(:unprocessable_entity, @invalid_params_message)}

  defp validate_operation(%Decimal{} = destination_amount),
    do:
      destination_amount
      |> Decimal.to_string(:normal)
      |> String.split(".")
      |> Enum.at(1)
      |> string_length()
      |> validate_decimal_places_length(destination_amount)

  defp string_length(nil), do: 0
  defp string_length(decimal_fraction), do: String.length(decimal_fraction)

  defp validate_decimal_places_length(
         length,
         destination_amount
       )
       when length == 5,
       do: {:ok, destination_amount}

  defp validate_decimal_places_length(
         length,
         _destination_amount
       )
       when length < 5,
       do: {:error, Error.build(:unprocessable_entity, @results_cant_be_trusted_message)}
end
