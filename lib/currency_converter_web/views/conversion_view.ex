defmodule CurrencyConverterWeb.ConversionView do
  use CurrencyConverterWeb, :view

  alias CurrencyConverter.Conversion
  alias CurrencyConverterWeb.PaginationView

  def render(
        "index.json",
        %{
          conversions: conversions,
          params: params
        }
      ),
      do: %{
        success: true,
        data: %{
          conversions: render_many(conversions, __MODULE__, "conversion_with_calculation.json")
        },
        metadata: render_one(params, PaginationView, "pagination.json")
      }

  def render(
        "show.json",
        %{conversion: conversion}
      ),
      do: %{success: true, data: render_one(conversion, __MODULE__, "conversion.json")}

  def render(
        "conversion_with_calculation.json",
        %{
          conversion:
            %Conversion{
              source_amount: source_amount,
              exchange_rate: exchange_rate
            } = conversion
        }
      ) do
    %{conversion: conversion_view_data} = render_one(conversion, __MODULE__, "conversion.json")

    case CurrencyConverter.calculate_destination_amount(exchange_rate, source_amount) do
      {:ok, destination_amount} ->
        Map.put(conversion_view_data, :destination_amount, format_decimal(destination_amount))

      _error ->
        conversion_view_data
    end
  end

  def render(
        "conversion.json",
        %{
          conversion: %Conversion{
            id: id,
            user_id: user_id,
            source_currency: source_currency,
            source_amount: source_amount,
            destination_currency: destination_currency,
            destination_amount: destination_amount,
            exchange_rate: exchange_rate,
            processed_at: processed_at
          }
        }
      ),
      do: %{
        conversion: %{
          id: id,
          user_id: user_id,
          source_currency: source_currency,
          source_amount: format_decimal(source_amount),
          destination_currency: destination_currency,
          destination_amount: format_decimal(destination_amount),
          exchange_rate: format_decimal(exchange_rate),
          processed_at: processed_at
        }
      }

  defp format_decimal(%Decimal{} = decimal),
    do:
      decimal
      |> Decimal.round(5)
      |> Decimal.to_string(:normal)

  defp format_decimal(nil), do: nil
end
