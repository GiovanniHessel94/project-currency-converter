defmodule CurrencyConverter.Conversions.CalculateDestinationAmountTest do
  use ExUnit.Case, async: true

  alias CurrencyConverter.{
    Conversions.CalculateDestinationAmount,
    Error
  }

  describe "call/2" do
    test "when the given params are valid, the calculated destination_amount" do
      exchange_rate = Decimal.new("1.090251")
      source_amount = Decimal.new(10)

      response = CalculateDestinationAmount.call(exchange_rate, source_amount)

      expected_response = {:ok, Decimal.new("10.90251")}

      assert response == expected_response
    end

    test """
      guarantees consistent outputs with results up to
      38 digits of precision which 5 are decimal places
    """ do
      exchange_rate = Decimal.new(2)
      source_amount = Decimal.new("100100100100100100100100100100100.12345")

      response = CalculateDestinationAmount.call(exchange_rate, source_amount)

      expected_response = {:ok, Decimal.new("200200200200200200200200200200200.24690")}

      assert response == expected_response
    end

    test """
      when operations exceeds 38 digits of precision, returns
      are error indicating that the result can't be trusted
    """ do
      exchange_rate = Decimal.new("1.00001")
      source_amount = Decimal.new("999999999999999999999999999999999.99999")

      response = CalculateDestinationAmount.call(exchange_rate, source_amount)

      expected_response = {
        :error,
        %Error{
          result: "this operations exceeds the decimal precision so results can't be trusted",
          status: :unprocessable_entity
        }
      }

      assert response == expected_response
    end

    test "when the params are invalid, as when one of then are negative returns an error" do
      exchange_rate = Decimal.new(-1)
      source_amount = Decimal.new("999999999999999999999999999999999.99999")

      response = CalculateDestinationAmount.call(exchange_rate, source_amount)

      expected_response = {
        :error,
        %Error{
          result: "invalid params to calculate the destination amount",
          status: :unprocessable_entity
        }
      }

      assert response == expected_response
    end
  end
end
