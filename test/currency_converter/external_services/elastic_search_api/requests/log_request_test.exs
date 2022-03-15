defmodule CurrencyConverter.ExternalServices.ElasticSearchApi.Requests.LogRequestTest do
  use ExUnit.Case, async: true

  alias CurrencyConverter.ExternalServices.ElasticSearchApi.Requests.LogRequest
  alias CurrencyConverter.Constants.Requests.{Events, Types}
  alias CurrencyConverter.{Error, Request, TestUtils}
  alias Plug.Conn

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

  describe "call/2" do
    setup do
      bypass = Bypass.open()

      {:ok, bypass: bypass}
    end

    test "when the request has log_request as false, returns an error" do
      request = %Request{@request | log_request: false}

      response = LogRequest.call("", request)

      expected_response = {
        :error,
        %Error{
          result: "request has an invalid event or type, or log request is false",
          status: :unprocessable_entity
        }
      }

      assert response == expected_response
    end

    test "when the request has an invalid event, returns an error" do
      request = %Request{@request | event: "event"}

      response = LogRequest.call("", request)

      expected_response = {
        :error,
        %Error{
          result: "request has an invalid event or type, or log request is false",
          status: :unprocessable_entity
        }
      }

      assert response == expected_response
    end

    test "when the request has an invalid type, returns an error" do
      request = %Request{@request | type: "type"}

      response = LogRequest.call("", request)

      expected_response = {
        :error,
        %Error{
          result: "request has an invalid event or type, or log request is false",
          status: :unprocessable_entity
        }
      }

      assert response == expected_response
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

      Bypass.expect(bypass, "POST", "requests-logs/_doc", fn conn ->
        assert TestUtils.headers_in_request_headers?(@expected_headers, conn) == true

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

    test "when the api response contains an errors, returns an error", %{bypass: bypass} do
      url = TestUtils.endpoint_url(bypass.port)

      response_body = ~s({
        "error": {
          "root_cause": [
            {
              "type": "not_x_content_exception",
              "reason": "not_x_content_exception: Compressor detection can only be called on some xcontent bytes or compressed xcontent bytes"
            }
          ],
          "type": "mapper_parsing_exception",
          "reason": "failed to parse",
          "caused_by": {
            "type": "not_x_content_exception",
            "reason": "not_x_content_exception: Compressor detection can only be called on some xcontent bytes or compressed xcontent bytes"
          }
        },
        "status": 400
      })

      Bypass.expect(bypass, "POST", "requests-logs/_doc", fn conn ->
        assert TestUtils.headers_in_request_headers?(@expected_headers, conn) == true

        conn
        |> Conn.put_resp_header("content-type", "application/json")
        |> Conn.resp(400, response_body)
      end)

      response = LogRequest.call(url, @request)

      expected_response = {:error, %Error{status: 400, result: "failed to parse"}}

      assert response == expected_response
    end

    test "when there is a generic error, returns an error", %{bypass: bypass} do
      url = TestUtils.endpoint_url(bypass.port)

      Bypass.down(bypass)

      response = LogRequest.call(url, @request)

      expected_response = {
        :error,
        %Error{status: :service_unavailable, result: "service unavailable"}
      }

      assert response == expected_response
    end
  end
end
