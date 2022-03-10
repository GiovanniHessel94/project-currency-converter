defmodule CurrencyConverter.ElasticSearchApi.ClientTest do
  use ExUnit.Case, async: true

  alias Plug.Conn

  alias CurrencyConverter.ElasticSearchApi.Requests.LogRequest
  alias CurrencyConverter.Constants.Requests.{Events, Types}
  alias CurrencyConverter.{Request, TestUtils}

  @request %Request{
    event: Events.get_fetch_exchange_rates_event(),
    method: "GET",
    response_time: 1000,
    status: 200,
    type: Types.get_external_type(),
    url: "http://api.exchangeratesapi.io/v1/latest",
    log_request: true,
    options: [timeout: 5000],
    query_params: %{base: "EUR", symbols: "BRL,JPY"},
    request_body: nil,
    request_headers: [],
    response_body: %{
      success: true,
      base: "EUR",
      date: "2022-03-05"
    },
    response_headers: [
      "Content-Type": "application/json; Charset=UTF-8"
    ]
  }

  describe "log_request/1" do
    setup do
      bypass = Bypass.open()

      {:ok, bypass: bypass}
    end

    test "when the request is successfully logged, returns the log info", %{bypass: bypass} do
      url = TestUtils.endpoint_url(bypass.port)

      response_body = ~s({
          "_index": "requests",
          "_id": "_LGFa38Bl2s6blMJ4rqm",
          "_version": 1,
          "result": "created",
          "_shards": {
            "total": 2,
            "successful": 2,
            "failed": 0
          },
          "_seq_no": 2,
          "_primary_term": 1
        })

      Bypass.expect(bypass, "POST", "requests/_doc", fn conn ->
        conn
        |> Conn.put_resp_header("content-type", "application/json")
        |> Conn.resp(200, response_body)
      end)

      response = LogRequest.call(url, @request)

      expected_response = {
        :ok,
        %{
          "_id" => "_LGFa38Bl2s6blMJ4rqm",
          "_index" => "requests",
          "_primary_term" => 1,
          "_seq_no" => 2,
          "_shards" => %{"failed" => 0, "successful" => 2, "total" => 2},
          "_version" => 1,
          "result" => "created"
        }
      }

      assert response == expected_response
    end
  end
end
