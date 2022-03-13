defmodule CurrencyConverter.ElasticSearchApi.ClientTest do
  use ExUnit.Case, async: true

  alias Plug.Conn

  alias CurrencyConverter.ElasticSearchApi.Client
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

  @expected_headers [
    {"authorization", "Basic Og=="},
    {"content-type", "application/json"},
    {"kbn-xsrf", "true"}
  ]

  describe "log_request/1" do
    setup do
      bypass = Bypass.open()

      {:ok, bypass: bypass}
    end

    test """
          when the elastic search integration is enabled, log
          the request successfully and returns the log info
         """,
         %{bypass: bypass} do
      url = TestUtils.endpoint_url(bypass.port)

      System.put_env("ELASTIC_SEARCH_API_BASE_URL", url)
      System.put_env("ELASTIC_SEARCH_API_ENABLED", "true")

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

      Bypass.expect(bypass, "POST", "requests-logs/_doc", fn conn ->
        assert TestUtils.headers_in_request_headers?(@expected_headers, conn) == true

        conn
        |> Conn.put_resp_header("content-type", "application/json")
        |> Conn.resp(200, response_body)
      end)

      response = Client.log_request(@request)

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

    test """
      when the elastic search integration is disabled, returns an appropriated message
    """ do
      System.put_env("ELASTIC_SEARCH_API_ENABLED", "false")

      response = Client.log_request(@request)

      expected_response = {:ok, "elastic search disabled"}

      assert response == expected_response
    end
  end
end
