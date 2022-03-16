defmodule CurrencyConverter.Conversions.ConvertTest do
  use CurrencyConverter.DataCase, async: true

  import CurrencyConverter.Factory

  alias CurrencyConverter.{
    Conversions.Convert,
    Error,
    ExchangeRates
  }

  setup_all do
    base_conversion =
      build(
        :conversion,
        source_amount: Decimal.new(10),
        source_currency: "BRL",
        destination_currency: "USD"
      )

    base_exchange_struct =
      ExchangeRates.build(
        "EUR",
        %{"BRL" => 5.516996, "USD" => 1.090251},
        1_646_780_822
      )

    {:ok, base_conversion: base_conversion, base_exchange_struct: base_exchange_struct}
  end

  describe "call/2" do
    test """
           when the given params are valid, returns
           the calculated conversion attrs
         """,
         %{
           base_conversion: base_conversion,
           base_exchange_struct: base_exchange_struct
         } do
      response = Convert.call(base_exchange_struct, base_conversion)

      expected_destination_amount = Decimal.new("1.97617")
      expected_exchange_rate = Decimal.new("0.19761678275641309147224322801756608125")

      assert {
               :ok,
               %{
                 destination_amount: ^expected_destination_amount,
                 exchange_rate: ^expected_exchange_rate,
                 processed_at: _processed_at
               }
             } = response
    end

    test """
           guarantees consistent outputs with results up to
           38 digits of precision which 5 are decimal places
         """,
         %{
           base_conversion: base_conversion,
           base_exchange_struct: base_exchange_struct
         } do
      source_amount = Decimal.new("100100100100100100100100100100100.12345")

      exchange_rates = %{
        "BRL" => 0.50000,
        "USD" => 1.0000
      }

      conversion = Map.put(base_conversion, :source_amount, source_amount)
      exchange_struct = Map.put(base_exchange_struct, :exchange_rates, exchange_rates)

      response = Convert.call(exchange_struct, conversion)

      expected_destination_amount = Decimal.new("200200200200200200200200200200200.24690")
      expected_exchange_rate = Decimal.new("2")

      assert {
               :ok,
               %{
                 destination_amount: ^expected_destination_amount,
                 exchange_rate: ^expected_exchange_rate,
                 processed_at: _processed_at
               }
             } = response
    end

    test """
           when operations exceeds 38 digits of precision, returns
           are error indicating that the result can't be trusted
         """,
         %{
           base_conversion: base_conversion,
           base_exchange_struct: base_exchange_struct
         } do
      source_amount = Decimal.new("999999999999999999999999999999999.12345")

      exchange_rates = %{
        "BRL" => 0.5000,
        "USD" => 5.0000
      }

      conversion = Map.put(base_conversion, :source_amount, source_amount)
      exchange_struct = Map.put(base_exchange_struct, :exchange_rates, exchange_rates)

      response = Convert.call(exchange_struct, conversion)

      assert {
               :error,
               %CurrencyConverter.Error{
                 result:
                   "this operations exceeds the decimal precision so results can't be trusted",
                 status: :unprocessable_entity
               }
             } = response
    end

    test """
           when the source_currency aren't in the
           available currencies, returns an error
         """,
         %{
           base_conversion: base_conversion,
           base_exchange_struct: base_exchange_struct
         } do
      conversion = Map.put(base_conversion, :source_currency, "BARRA DE OURO")

      response = Convert.call(base_exchange_struct, conversion)

      expected_response = {
        :error,
        %Error{
          result: "invalid source amount, source currency or destination currency",
          status: :unprocessable_entity
        }
      }

      assert response == expected_response
    end

    test """
           when the destination_currency aren't in the
           available currencies, returns an error
         """,
         %{
           base_conversion: base_conversion,
           base_exchange_struct: base_exchange_struct
         } do
      conversion = Map.put(base_conversion, :destination_currency, "BARRA DE OURO")

      response = Convert.call(base_exchange_struct, conversion)

      expected_response = {
        :error,
        %Error{
          result: "invalid source amount, source currency or destination currency",
          status: :unprocessable_entity
        }
      }

      assert response == expected_response
    end

    test """
           when the exchange_struct is not a map, returns an error
         """,
         %{
           base_conversion: base_conversion,
           base_exchange_struct: base_exchange_struct
         } do
      exchange_struct = Map.put(base_exchange_struct, :exchange_rates, nil)

      response = Convert.call(exchange_struct, base_conversion)

      expected_response = {
        :error,
        %Error{
          result: "can't fetch exchange rates",
          status: :unprocessable_entity
        }
      }

      assert response == expected_response
    end

    test """
           when the source_currency is valid but there is not
           exchange rates for it, returns an error
         """,
         %{
           base_conversion: base_conversion,
           base_exchange_struct: base_exchange_struct
         } do
      conversion = Map.put(base_conversion, :source_currency, "ARS")

      response = Convert.call(base_exchange_struct, conversion)

      expected_response = {
        :error,
        %Error{
          result: "can't fetch the exchange rate of the \"ARS\" currency",
          status: :unprocessable_entity
        }
      }

      assert response == expected_response
    end

    test """
           when the destination_currency is valid but there is not
           exchange rates for it, returns an error
         """,
         %{
           base_conversion: base_conversion,
           base_exchange_struct: base_exchange_struct
         } do
      conversion = Map.put(base_conversion, :destination_currency, "WST")

      response = Convert.call(base_exchange_struct, conversion)

      expected_response = {
        :error,
        %Error{
          result: "can't fetch the exchange rate of the \"WST\" currency",
          status: :unprocessable_entity
        }
      }

      assert response == expected_response
    end
  end
end
