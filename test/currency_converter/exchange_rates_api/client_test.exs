defmodule CurrencyConverter.ExchangeRatesApi.ClientTest do
  use CurrencyConverter.DataCase, async: true

  import CurrencyConverter.Factory
  import Mox

  alias Plug.Conn

  alias CurrencyConverter.ElasticSearchApi.ClientMock
  alias CurrencyConverter.ExchangeRatesApi.Client
  alias CurrencyConverter.TestUtils

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
           when the exchange rates are successfully fetched,
           returns the exchange rates info
         """,
         %{bypass: bypass, base_conversion: base_conversion} do
      stub(ClientMock, :log_request, fn _ -> {:ok, %{success: true}} end)

      url = TestUtils.endpoint_url(bypass.port)
      System.put_env("EXCHANGE_RATES_API_BASE_URL", url)

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

      response = Client.fetch_exchange_rates(base_conversion)

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
  end
end
