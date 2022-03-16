defmodule CurrencyConverter.Decimals.Create do
  @moduledoc """
    Create decimals module.

    Responsible for handling the creation of
    decimals from external sources.
  """

  alias CurrencyConverter.{
    Decimals.SetContextPrecision,
    Error,
    Utils
  }

  @results_cant_be_trusted_message "this operations exceeds the decimal precision so results can't be trusted"
  @cant_create_decimal_message "can't create a decimal with the given params"

  def call(number_string) when is_binary(number_string) do
    SetContextPrecision.call()

    case validate_is_number(number_string) do
      true -> do_create_decimal(number_string)
      false -> {:error, Error.build(:unprocessable_entity, @cant_create_decimal_message)}
    end
  end

  def call(number),
    do:
      number
      |> Utils.value_to_string()
      |> call()

  def get_results_cant_be_trusted_message, do: @results_cant_be_trusted_message
  def get_cant_create_decimal_message, do: @cant_create_decimal_message

  defp validate_is_number(number_string) do
    case Integer.parse(number_string) do
      {_integer, decimal_fraction} -> validate_decimal_fraction(decimal_fraction)
      _error -> false
    end
  end

  defp validate_decimal_fraction(""), do: true

  defp validate_decimal_fraction(decimal_fraction),
    do:
      decimal_fraction
      |> String.slice(0, 5)
      |> String.replace_prefix(".", "")
      |> String.match?(~r/^\d+$/)

  defp do_create_decimal(number_string),
    do:
      number_string
      |> removes_exceeding_decimal_places()
      |> ensure_decimal_string_precision()
      |> concat_integer_part_and_decimal_fraction()
      |> creates_decimal_struct()

  defp removes_exceeding_decimal_places(value),
    do:
      value
      |> String.split(".")
      |> do_removes_exceeding_decimal_places()

  defp do_removes_exceeding_decimal_places([integer_part | _tail] = splitted_value)
       when length(splitted_value) > 1,
       do:
         splitted_value
         |> Enum.at(1)
         |> String.slice(0, 5)
         |> then(&{integer_part, &1})

  defp do_removes_exceeding_decimal_places([integer_part]), do: {integer_part, nil}

  defp ensure_decimal_string_precision({integer_part, _decimal_fraction} = tuple) do
    if String.length(integer_part) > 33 do
      {:error, Error.build(:unprocessable_entity, @results_cant_be_trusted_message)}
    else
      tuple
    end
  end

  defp concat_integer_part_and_decimal_fraction({
         integer_part,
         nil
       })
       when is_binary(integer_part),
       do: "#{integer_part}"

  defp concat_integer_part_and_decimal_fraction({
         integer_part,
         decimal_fraction
       })
       when is_binary(integer_part) and is_binary(decimal_fraction),
       do: "#{integer_part}.#{decimal_fraction}"

  defp concat_integer_part_and_decimal_fraction({:error, _reason} = result), do: result

  defp creates_decimal_struct(decimal_string) when is_binary(decimal_string) do
    decimal =
      decimal_string
      |> Decimal.new()
      |> Decimal.round(5)

    {:ok, decimal}
  end

  defp creates_decimal_struct({:error, _reason} = result), do: result
end
