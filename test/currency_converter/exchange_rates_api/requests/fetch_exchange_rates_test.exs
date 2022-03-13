defmodule CurrencyConverter.ExchangeRatesApi.Requests.FetchExchangeRatesTest do
  use CurrencyConverter.DataCase, async: true

  import CurrencyConverter.Factory
  import Mox

  alias Plug.Conn

  alias CurrencyConverter.ElasticSearchApi.ClientMock
  alias CurrencyConverter.ExchangeRatesApi.Requests.FetchExchangeRates
  alias CurrencyConverter.{Conversion, Error, TestUtils}

  System.put_env("EXCHANGE_RATES_API_ACCESS_KEY", "banana")

  @expected_query_params %{
    base: "EUR",
    access_key: "banana",
    symbols: "BRL,USD"
  }

  describe "call/2" do
    setup do
      bypass = Bypass.open()

      base_conversion = build(:conversion)

      {:ok, bypass: bypass, base_conversion: base_conversion}
    end

    test """
           when source_currency in conversion is invalid, returns an error
         """,
         %{base_conversion: base_conversion} do
      conversion = %Conversion{base_conversion | source_currency: "INVALID"}

      response = FetchExchangeRates.call("", conversion)

      expected_response = {
        :error,
        %Error{
          result: "invalid source currency or destination currency",
          status: :unprocessable_entity
        }
      }

      assert response == expected_response
    end

    test """
           when destination_currency in conversion is invalid, returns an error
         """,
         %{base_conversion: base_conversion} do
      conversion = %Conversion{base_conversion | destination_currency: "INVALID"}

      response = FetchExchangeRates.call("", conversion)

      expected_response = {
        :error,
        %Error{
          result: "invalid source currency or destination currency",
          status: :unprocessable_entity
        }
      }

      assert response == expected_response
    end

    test """
           when the exchange rates are successfully fetched,
           returns the exchange rates info
         """,
         %{bypass: bypass, base_conversion: base_conversion} do
      stub(ClientMock, :log_request, fn _ -> {:ok, %{success: true}} end)

      url = TestUtils.endpoint_url(bypass.port)

      response_body = ~s({
        "success": true,
        "timestamp": 1647091083,
        "base": "EUR",
        "date": "2022-03-12",
        "rates": {
          "BRL": 5.537896,
          "USD": 1.091202,
          "JPY": 128.022578
        }
      })

      Bypass.expect(bypass, "GET", "v1/latest", fn conn ->
        TestUtils.query_params_in_request_query_params?(@expected_query_params, conn)

        conn
        |> Conn.put_resp_header("content-type", "application/json")
        |> Conn.resp(200, response_body)
      end)

      response = FetchExchangeRates.call(url, base_conversion)

      expected_response = {
        :ok,
        %CurrencyConverter.ExchangeRates{
          base: "EUR",
          exchange_rates: %{"BRL" => 5.537896, "JPY" => 128.022578, "USD" => 1.091202},
          timestamp: 1_647_091_083
        }
      }

      assert response == expected_response
    end

    test """
           when the api response contains an errors, returns an error
         """,
         %{bypass: bypass, base_conversion: base_conversion} do
      stub(ClientMock, :log_request, fn _ -> {:ok, %{success: true}} end)

      url = TestUtils.endpoint_url(bypass.port)

      response_body = ~s({
        "error": {
          "code": "missing_access_key",
          "message": "you have not supplied an api access key. [required format: access_key=your_access_key]"
        }
      })

      Bypass.expect(bypass, "GET", "v1/latest", fn conn ->
        TestUtils.query_params_in_request_query_params?(@expected_query_params, conn)

        conn
        |> Conn.put_resp_header("content-type", "application/json")
        |> Conn.resp(400, response_body)
      end)

      response = FetchExchangeRates.call(url, base_conversion)

      expected_response = {
        :error,
        %CurrencyConverter.Error{
          result:
            "an error occurred while communicating with the exchange rates api." <>
              " you have not supplied an api access key. [required format: access_key=your_access_key]",
          status: :unprocessable_entity
        }
      }

      assert response == expected_response
    end

    test "when there is a generic error, returns an error", %{
      bypass: bypass,
      base_conversion: base_conversion
    } do
      stub(ClientMock, :log_request, fn _ -> {:ok, %{success: true}} end)

      url = TestUtils.endpoint_url(bypass.port)

      Bypass.down(bypass)

      response = FetchExchangeRates.call(url, base_conversion)

      expected_response = {
        :error,
        %Error{status: :service_unavailable, result: "service unavailable"}
      }

      assert response == expected_response
    end
  end
end
