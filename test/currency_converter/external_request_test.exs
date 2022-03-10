defmodule CurrencyConverter.ExternalRequestTest do
  use ExUnit.Case, async: true

  import Mox

  alias Plug.Conn

  alias CurrencyConverter.ElasticSearchApi.ClientMock
  alias CurrencyConverter.ElasticSearchApi.ExternalService, as: ElasticExternalService
  alias CurrencyConverter.{Error, Request, TestUtils}
  alias CurrencyConverter.ExternalRequest
  alias CurrencyConverter.Constants.Requests.{Events, Types}

  @request_event Events.get_fetch_exchange_rates_event()
  @request_type Types.get_external_type()

  @request %Request{
    event: @request_event,
    method: "GET",
    type: @request_type,
    url: "",
    log_request: true,
    options: [timeout: 5000],
    query_params: %{base: "EUR", symbols: "BRL,JPY"},
    request_headers: [Authorization: "Basic #{Base.encode64("username:password")}"]
  }

  @fuse_name CurrencyConverter.ElasticSearchApi.ExternalService

  @retry_opts %ExternalService.RetryOptions{
    backoff: {:exponential, 500},
    expiry: 5_000
  }

  setup_all do
    ElasticExternalService.start()
  end

  describe "call/3" do
    setup do
      bypass = Bypass.open()

      verify_on_exit!()

      {:ok, bypass: bypass}
    end

    test "when the request is successful, returns a poison response", %{bypass: bypass} do
      stub(ClientMock, :log_request, fn _ -> {:ok, %{success: true}} end)

      url = "#{TestUtils.endpoint_url(bypass.port)}v1/latest"

      request = %Request{@request | url: url}

      response_body = ~s({
        "success": true,
        "timestamp": 1646780822,
        "base": "EUR",
        "date": "2022-03-08",
        "rates": {
          "BRL": 5.516996,
          "USD": 1.090251,
          "JPY": 126.131524
        }
      })

      Bypass.expect(bypass, "GET", "v1/latest", fn conn ->
        conn
        |> Conn.put_resp_header("content-type", "application/json")
        |> Conn.resp(200, response_body)
      end)

      response = ExternalRequest.call(request, @fuse_name, @retry_opts)

      expected_url = "#{url}?base=EUR&symbols=BRL%2CJPY"

      assert {
               :ok,
               %HTTPoison.Response{
                 body: %{
                   "base" => "EUR",
                   "date" => "2022-03-08",
                   "rates" => %{"BRL" => 5.516996, "JPY" => 126.131524, "USD" => 1.090251},
                   "success" => true,
                   "timestamp" => 1_646_780_822
                 },
                 headers: [
                   {"cache-control", "max-age=0, private, must-revalidate"},
                   {"content-length", "231"},
                   {"content-type", "application/json"},
                   {"date", _date},
                   {"server", "Cowboy"}
                 ],
                 request: %HTTPoison.Request{
                   body: "",
                   headers: [Authorization: "Basic dXNlcm5hbWU6cGFzc3dvcmQ="],
                   method: "GET",
                   options: [timeout: 5000],
                   params: %{base: "EUR", symbols: "BRL,JPY"},
                   url: ^expected_url
                 },
                 request_url: ^expected_url,
                 status_code: 200
               }
             } = response
    end

    test """
           when the response body is gzipped with gzip,
           unzips it and returns a poison response
         """,
         %{bypass: bypass} do
      stub(ClientMock, :log_request, fn _ -> {:ok, %{success: true}} end)

      url = "#{TestUtils.endpoint_url(bypass.port)}v1/latest"

      request = %Request{@request | url: url}

      Bypass.expect(bypass, "GET", "v1/latest", fn conn ->
        conn
        |> Conn.put_resp_header("content-type", "application/json")
        |> Conn.put_resp_header("content-encoding", "gzip")
        |> Conn.resp(200, :zlib.gzip(~S({"success": true})))
      end)

      response = ExternalRequest.call(request, @fuse_name, @retry_opts)

      assert {
               :ok,
               %HTTPoison.Response{
                 body: %{"success" => true},
                 status_code: 200
               }
             } = response
    end

    test """
           when the response body is gzipped with x-gzip,
           unzips it and returns a poison response
         """,
         %{bypass: bypass} do
      stub(ClientMock, :log_request, fn _ -> {:ok, %{success: true}} end)

      url = "#{TestUtils.endpoint_url(bypass.port)}v1/latest"

      request = %Request{@request | url: url}

      Bypass.expect(bypass, "GET", "v1/latest", fn conn ->
        conn
        |> Conn.put_resp_header("content-type", "application/json")
        |> Conn.put_resp_header("content-encoding", "x-gzip")
        |> Conn.resp(200, :zlib.gzip(~S({"success": true})))
      end)

      response = ExternalRequest.call(request, @fuse_name, @retry_opts)

      assert {
               :ok,
               %HTTPoison.Response{
                 body: %{"success" => true},
                 status_code: 200
               }
             } = response
    end

    test """
           when the response body is invalid, returns a
           poison response with an empty response body
         """,
         %{bypass: bypass} do
      stub(ClientMock, :log_request, fn _ -> {:ok, %{success: true}} end)

      url = "#{TestUtils.endpoint_url(bypass.port)}v1/latest"

      request = %Request{@request | url: url}

      Bypass.expect(bypass, "GET", "v1/latest", fn conn ->
        conn
        |> Conn.put_resp_header("content-type", "application/json")
        |> Conn.resp(200, ~S(%{"success": true}))
      end)

      response = ExternalRequest.call(request, @fuse_name, @retry_opts)

      assert {
               :ok,
               %HTTPoison.Response{
                 body: %{},
                 status_code: 200
               }
             } = response
    end

    test "when the request has errors, returns an error", %{bypass: bypass} do
      stub(ClientMock, :log_request, fn _ -> {:ok, %{success: true}} end)

      url = "#{TestUtils.endpoint_url(bypass.port)}v1/latest"

      request = %Request{@request | url: url}

      Bypass.expect(bypass, "GET", "v1/latest", fn conn ->
        conn
        |> Conn.put_resp_header("content-type", "application/json")
        |> Conn.resp(500, ~S({"success": false}))
      end)

      response = ExternalRequest.call(request, @fuse_name, @retry_opts)

      assert {
               :error,
               %Error{
                 result: "service unavailable",
                 status: :service_unavailable
               }
             } = response
    end

    test "when the service is unavailable, returns an error", %{bypass: bypass} do
      stub(ClientMock, :log_request, fn _ -> {:ok, %{success: true}} end)

      url = "#{TestUtils.endpoint_url(bypass.port)}v1/latest"

      request = %Request{@request | url: url}

      Bypass.down(bypass)

      response = ExternalRequest.call(request, @fuse_name, @retry_opts)

      assert {
               :error,
               %Error{
                 result: "service unavailable",
                 status: :service_unavailable
               }
             } = response
    end

    test """
           when the request log_request is false, doesn't call
           the log request from elastic search client
         """,
         %{bypass: bypass} do
      expect(ClientMock, :log_request, 0, fn _ -> nil end)

      url = "#{TestUtils.endpoint_url(bypass.port)}v1/latest"

      request = %Request{@request | url: url, log_request: false}

      Bypass.expect(bypass, "GET", "v1/latest", fn conn ->
        conn
        |> Conn.put_resp_header("content-type", "application/json")
        |> Conn.resp(200, ~s({"success": true}))
      end)

      response = ExternalRequest.call(request, @fuse_name, @retry_opts)

      assert {:ok, _response} = response
    end

    test """
           when the request log_request is true, call the log
           request from elastic search client with the request
         """,
         %{bypass: bypass} do
      expect(
        ClientMock,
        :log_request,
        1,
        fn %Request{
             event: event,
             method: method,
             type: type
           } ->
          assert event == @request_event
          assert method == "GET"
          assert type == @request_type

          {:ok, %{"success" => true}}
        end
      )

      url = "#{TestUtils.endpoint_url(bypass.port)}v1/latest"

      request = %Request{@request | url: url, log_request: true}

      Bypass.expect(bypass, "GET", "v1/latest", fn conn ->
        conn
        |> Conn.put_resp_header("content-type", "application/json")
        |> Conn.resp(200, ~s({"success": true}))
      end)

      response = ExternalRequest.call(request, @fuse_name, @retry_opts)

      assert {:ok, _response} = response
    end
  end
end
