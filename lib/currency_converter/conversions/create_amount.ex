defmodule CurrencyConverter.Conversions.CreateAmount do
  @moduledoc """
    Create decimal amount module.

    Responsible for handling the creation of
    the decimal from received amount.
  """

  alias CurrencyConverter.{
    Decimals.SetContextPrecision,
    Error,
    Utils
  }

  @results_cant_be_trusted_message "source_amount is not within the precision of 38 digits which 5 are for decimal places"
  @cant_create_amount_message "source_amount is not a valid number string representation"

  def call(number_string) when is_binary(number_string) do
    SetContextPrecision.call()

    case validate_is_number(number_string) do
      true -> do_create_amount(number_string)
      false -> {:error, Error.build(:bad_request, @cant_create_amount_message)}
    end
  end

  def call(number),
    do:
      number
      |> Utils.value_to_string()
      |> call()

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
      |> String.replace_prefix(".", "")
      |> String.match?(~r/^\d+$/)

  defp do_create_amount(number_string),
    do:
      number_string
      |> removes_exceeding_decimal_places()
      |> ensure_decimal_string_precision()
      |> concat_integer_part_and_decimal_fraction()
      |> create_decimal()

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
      {:error, Error.build(:bad_request, @results_cant_be_trusted_message)}
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

  defp create_decimal(decimal_string) when is_binary(decimal_string) do
    decimal =
      decimal_string
      |> Decimal.new()
      |> Decimal.round(5)

    {:ok, decimal}
  end

  defp create_decimal({:error, _reason} = result), do: result
end
