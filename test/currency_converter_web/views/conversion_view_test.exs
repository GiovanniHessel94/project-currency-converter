defmodule CurrencyConverterWeb.ConversionViewTest do
  use CurrencyConverterWeb.ConnCase, async: true

  import CurrencyConverter.Factory
  import Phoenix.View, only: [render: 3]

  alias CurrencyConverter.Conversion
  alias CurrencyConverterWeb.ConversionView

  setup_all do
    user_id = "12381283"

    conversions = [
      conversion = build(:conversion, user_id: user_id),
      build(:conversion, user_id: user_id)
    ]

    {:ok, conversions: conversions, conversion: conversion}
  end

  describe "conversion.json" do
    test """
           when the result is a conversion, renders it
         """,
         %{
           conversion:
             %Conversion{
               user_id: user_id,
               exchange_rate: exchange_rate
             } = conversion
         } do
      conversion_param = %{conversion: conversion}

      response = render(ConversionView, "conversion.json", conversion_param)

      expected_exchange_rate = Decimal.to_string(exchange_rate, :normal)

      assert %{
               conversion: %{
                 destination_amount: nil,
                 destination_currency: "USD",
                 exchange_rate: ^expected_exchange_rate,
                 id: nil,
                 processed_at: _processed_at,
                 source_amount: "10.00000",
                 source_currency: "BRL",
                 user_id: ^user_id
               }
             } = response
    end
  end

  describe "conversion_with_calculation.json" do
    test """
          when the result is a conversion, renders it with the
          calculated destination_amount
         """,
         %{
           conversion:
             %Conversion{
               user_id: user_id,
               exchange_rate: exchange_rate,
               source_amount: source_amount
             } = conversion
         } do
      {
        :ok,
        destination_amount
      } = CurrencyConverter.calculate_destination_amount(exchange_rate, source_amount)

      conversion_param = %{conversion: conversion}

      response = render(ConversionView, "conversion_with_calculation.json", conversion_param)

      expected_destination_amount = Decimal.to_string(destination_amount, :normal)
      expected_exchange_rate = Decimal.to_string(exchange_rate, :normal)

      assert %{
               destination_amount: ^expected_destination_amount,
               destination_currency: "USD",
               exchange_rate: ^expected_exchange_rate,
               id: nil,
               processed_at: _processed_at,
               source_amount: "10.00000",
               source_currency: "BRL",
               user_id: ^user_id
             } =
               response
    end
  end

  describe "show.json" do
    test """
          when the result is a conversion, renders it with success true
         """,
         %{
           conversion:
             %Conversion{
               user_id: user_id,
               exchange_rate: exchange_rate
             } = conversion
         } do
      conversion_param = %{conversion: conversion}

      response = render(ConversionView, "show.json", conversion_param)

      expected_exchange_rate = Decimal.to_string(exchange_rate, :normal)

      assert %{
               success: true,
               data: %{
                 conversion: %{
                   destination_amount: nil,
                   destination_currency: "USD",
                   exchange_rate: ^expected_exchange_rate,
                   id: nil,
                   processed_at: _processed_at,
                   source_amount: "10.00000",
                   source_currency: "BRL",
                   user_id: ^user_id
                 }
               }
             } = response
    end
  end

  describe "index.json" do
    test """
          when the result is a list of conversions and pagination params,
          renders the conversions, the pagination params and success true
         """,
         %{
           conversions:
             [
               %Conversion{
                 user_id: user_id,
                 exchange_rate: exchange_rate_1,
                 source_amount: source_amount_1
               },
               %Conversion{
                 exchange_rate: exchange_rate_2,
                 source_amount: source_amount_2
               }
             ] = conversions
         } do
      {
        :ok,
        destination_amount_1
      } = CurrencyConverter.calculate_destination_amount(exchange_rate_1, source_amount_1)

      {
        :ok,
        destination_amount_2
      } = CurrencyConverter.calculate_destination_amount(exchange_rate_2, source_amount_2)

      result_param = %{
        conversions: conversions,
        params: %{
          "page" => 1,
          "limit" => 5,
          "order_direction" => :asc
        }
      }

      response = render(ConversionView, "index.json", result_param)

      expected_destination_amount_1 = Decimal.to_string(destination_amount_1, :normal)
      expected_exchange_rate_1 = Decimal.to_string(exchange_rate_1, :normal)

      expected_destination_amount_2 = Decimal.to_string(destination_amount_2, :normal)
      expected_exchange_rate_2 = Decimal.to_string(exchange_rate_2, :normal)

      assert %{
               success: true,
               metadata: %{limit: 5, order_direction: :asc, page: 1},
               data: %{
                 conversions: [
                   %{
                     destination_amount: ^expected_destination_amount_1,
                     destination_currency: "USD",
                     exchange_rate: ^expected_exchange_rate_1,
                     id: _id_1,
                     processed_at: _processed_at_1,
                     source_amount: "10.00000",
                     source_currency: "BRL",
                     user_id: ^user_id
                   },
                   %{
                     destination_amount: ^expected_destination_amount_2,
                     destination_currency: "USD",
                     exchange_rate: ^expected_exchange_rate_2,
                     id: _id_2,
                     processed_at: _processed_at_2,
                     source_amount: "10.00000",
                     source_currency: "BRL",
                     user_id: ^user_id
                   }
                 ]
               }
             } = response
    end
  end
end
