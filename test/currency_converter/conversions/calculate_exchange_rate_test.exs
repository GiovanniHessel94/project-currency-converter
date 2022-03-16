defmodule CurrencyConverter.Conversions.CalculateExchangeRateTest do
  use ExUnit.Case, async: true

  alias CurrencyConverter.{
    Conversions.CalculateExchangeRate,
    Error
  }

  describe "call/2" do
    test "when the given params are valid, the calculated destination_amount" do
      source_base_exchange_rate = Decimal.new("5.516996")
      destination_base_exchange_rate = Decimal.new("1.090251")

      response =
        CalculateExchangeRate.call(
          source_base_exchange_rate,
          destination_base_exchange_rate
        )

      expected_response = {:ok, Decimal.new("0.19761678275641309147224322801756608125")}

      assert response == expected_response
    end

    test "when the params are invalid, as when one of then are negative returns an error" do
      source_base_exchange_rate = Decimal.new(-1)
      destination_base_exchange_rate = Decimal.new("1.090251")

      response =
        CalculateExchangeRate.call(
          source_base_exchange_rate,
          destination_base_exchange_rate
        )

      expected_response = {
        :error,
        %Error{
          result: "invalid params to calculate the exchange rate",
          status: :unprocessable_entity
        }
      }

      assert response == expected_response
    end
  end
end
