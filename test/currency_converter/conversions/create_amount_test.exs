defmodule CurrencyConverter.Conversions.CreateAmountTest do
  use ExUnit.Case, async: true

  alias CurrencyConverter.{Conversions.CreateAmount, Error}

  describe "call/1" do
    test """
      when the given number is a valid string representation,
      transforms it on string and returns the decimal
    """ do
      number = 30

      expected_response = {
        :ok,
        Decimal.new("30.00000")
      }

      response = CreateAmount.call(number)

      assert response == expected_response
    end

    test """
      when the given number is not a string, transforms it on string
      and returns the decimal
    """ do
      number = 30.5

      expected_response = {
        :ok,
        Decimal.new("30.50000")
      }

      response = CreateAmount.call(number)

      assert response == expected_response
    end

    test """
      when the given number is not a string represantation of a number,
      returns an error
    """ do
      number = "HEHEHE"

      expected_response = {
        :error,
        %Error{
          result: "can't create a decimal from the given amount",
          status: :unprocessable_entity
        }
      }

      response = CreateAmount.call(number)

      assert response == expected_response
    end

    test """
      when the given number decimal fraction is not a valid string represantation,
      returns an error
    """ do
      number = "30.5555.9"

      expected_response = {
        :error,
        %Error{
          result: "can't create a decimal from the given amount",
          status: :unprocessable_entity
        }
      }

      response = CreateAmount.call(number)

      assert response == expected_response
    end

    test """
      when the given number is a valid string representation
      that has less than five decimal places, returns an decimal
      with five decimal places
    """ do
      number = "25.123"

      expected_response = {
        :ok,
        Decimal.new("25.12300")
      }

      response = CreateAmount.call(number)

      assert response == expected_response
    end

    test """
      when the given number is a valid string representation
      that has more than five decimal places, ignores the
      exeeding decimal places and returns an decimal with
      five decimal places
    """ do
      number = "25.12345678910"

      expected_response = {
        :ok,
        Decimal.new("25.12345")
      }

      response = CreateAmount.call(number)

      assert response == expected_response
    end

    test """
      when the given number is a valid string representation
      but it's integer part exeeds 33 digits, returns an error
    """ do
      number = "9999999999999999999999999999999999.99999"

      expected_response = {
        :error,
        %Error{
          result: "this operations exceeds the decimal precision so results can't be trusted",
          status: :unprocessable_entity
        }
      }

      response = CreateAmount.call(number)

      assert response == expected_response
    end
  end

  describe "get_results_cant_be_trusted_message/0" do
    test "returns the results cant be trusted message" do
      response = CreateAmount.get_results_cant_be_trusted_message()

      expected_response =
        "this operations exceeds the decimal precision so results can't be trusted"

      assert response == expected_response
    end
  end

  describe "get_cant_create_amount_message/0" do
    test "returns the cant create decimal messagee" do
      response = CreateAmount.get_cant_create_amount_message()

      expected_response = "can't create a decimal from the given amount"

      assert response == expected_response
    end
  end
end
