defmodule CurrencyConverter.ExternalServices.ExchangeRatesApi.Requests.FetchExchangeRates.ResponseBuilderTest do
  use ExUnit.Case, async: true

  alias CurrencyConverter.ExternalServices.ExchangeRatesApi.Requests.FetchExchangeRates.ResponseBuilder
  alias CurrencyConverter.{Error, ExchangeRates}

  describe "call/1" do
    test """
     when the response has base, rates and timestamp keys,
     returns an exchange rates struct with the info
    """ do
      response_param = %{
        "base" => "EUR",
        "date" => "2022-03-08",
        "rates" => %{"BRL" => 5.516996, "JPY" => 126.131524, "USD" => 1.090251},
        "success" => true,
        "timestamp" => 1_646_780_822
      }

      response = ResponseBuilder.call(response_param)

      expected_response = {
        :ok,
        %ExchangeRates{
          base: "EUR",
          exchange_rates: %{"BRL" => 5.516996, "JPY" => 126.131524, "USD" => 1.090251},
          timestamp: 1_646_780_822
        }
      }

      assert response == expected_response
    end

    test "when the response don't has the base, rates, and timestamp keys returns an error" do
      response_param = %{
        "date" => "2022-03-08",
        "success" => true
      }

      response = ResponseBuilder.call(response_param)

      expected_response = {
        :error,
        %Error{
          result: "an error occurred while processing the exchange rates response",
          status: :unprocessable_entity
        }
      }

      assert response == expected_response
    end
  end
end
