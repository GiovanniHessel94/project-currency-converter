defmodule CurrencyConverter.ElasticSearchApi.Requests.LogRequests.BodyBuilderTest do
  use ExUnit.Case, async: true

  alias CurrencyConverter.ElasticSearchApi.Requests.LogRequests.BodyBuilder
  alias CurrencyConverter.Request

  setup_all do
    request = %Request{
      event: :event,
      method: "GET",
      response_time: 1000,
      status: 200,
      type: :type,
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

    {:ok, request: request}
  end

  describe "call/1" do
    test """
           when request has all the keys, returns the body with the data formated
         """,
         %{request: request} do
      expected_response_body = ~S({"base":"EUR","date":"2022-03-05","success":true})

      expected_response_headers = ~S({"Content-Type":"application/json; Charset=UTF-8"})

      assert %{
               "event" => "event",
               "created_at" => _created_at,
               "method" => "get",
               "options" => ~S({"timeout":5000}),
               "request_body" => "{}",
               "request_headers" => "{}",
               "response_body" => ^expected_response_body,
               "response_headers" => ^expected_response_headers,
               "response_time" => 1000,
               "status" => 200,
               "type" => "type",
               "url" => "http://api.exchangeratesapi.io/v1/latest?base=EUR&symbols=BRL%2CJPY"
             } =
               request
               |> BodyBuilder.call()
               |> Jason.decode!()
    end

    test """
           when request has event, returns it on body
         """,
         %{request: request} do
      expected_event = "event"

      request = %Request{request | event: expected_event}

      assert %{"event" => ^expected_event} =
               request
               |> BodyBuilder.call()
               |> Jason.decode!()
    end

    test """
           when request has method, returns it on body as a downcase string
         """,
         %{request: request} do
      request = %Request{request | method: "OPTIONS"}

      expected_method = "options"

      assert %{"method" => ^expected_method} =
               request
               |> BodyBuilder.call()
               |> Jason.decode!()
    end

    test """
           when request has options, returns it on body as string
         """,
         %{request: request} do
      request = %Request{request | options: [timeout: 5000]}

      expected_options = ~S({"timeout":5000})

      assert %{"options" => ^expected_options} =
               request
               |> BodyBuilder.call()
               |> Jason.decode!()
    end

    test """
           when there is invalid data on options,
           returns the options with error
         """,
         %{request: request} do
      request = %Request{request | options: %{map: {:b, :d}}}

      expected_options =
        ~S(%Protocol.UndefinedError{description: "Jason.Encoder protocol must always be explicitly implemented", protocol: Jason.Encoder, value: {:b, :d}})

      assert %{
               "options" => ^expected_options
             } =
               request
               |> BodyBuilder.call()
               |> Jason.decode!()
    end

    test """
           when request has request_body, returns it on body as string
         """,
         %{request: request} do
      request = %Request{request | request_body: %{base: "BRL", timestamp: 1_932_012_126}}

      expected_request_body = ~S({"base":"BRL","timestamp":1932012126})

      assert %{"request_body" => ^expected_request_body} =
               request
               |> BodyBuilder.call()
               |> Jason.decode!()
    end

    test """
           when there is invalid data on request_body,
           returns request_body with error
         """,
         %{request: request} do
      request = %Request{request | request_body: %{map: {:b, :d}}}

      expected_request_body =
        ~S(%Protocol.UndefinedError{description: "Jason.Encoder protocol must always be explicitly implemented", protocol: Jason.Encoder, value: {:b, :d}})

      assert %{
               "request_body" => ^expected_request_body
             } =
               request
               |> BodyBuilder.call()
               |> Jason.decode!()
    end

    test """
           when request has request_headers, returns it on body as string
         """,
         %{request: request} do
      request = %Request{request | request_headers: ["Content-Type": "application/json"]}

      expected_request_headers = ~S({"Content-Type":"application/json"})

      assert %{"request_headers" => ^expected_request_headers} =
               request
               |> BodyBuilder.call()
               |> Jason.decode!()
    end

    test """
           when there is invalid data on request_headers,
           returns request_headers with error
         """,
         %{request: request} do
      request = %Request{request | request_headers: %{map: {:b, :d}}}

      expected_request_headers =
        ~S(%Protocol.UndefinedError{description: "Jason.Encoder protocol must always be explicitly implemented", protocol: Jason.Encoder, value: {:b, :d}})

      assert %{
               "request_headers" => ^expected_request_headers
             } =
               request
               |> BodyBuilder.call()
               |> Jason.decode!()
    end

    test """
           when request has response_body, returns it on body as string
         """,
         %{request: request} do
      request = %Request{request | response_body: %{base: "EUR", timestamp: 1_646_480_522}}

      expected_response_body = ~S({"base":"EUR","timestamp":1646480522})

      assert %{"response_body" => ^expected_response_body} =
               request
               |> BodyBuilder.call()
               |> Jason.decode!()
    end

    test """
           when there is invalid data on response_body,
           returns response_body with error
         """,
         %{request: request} do
      request = %Request{request | response_body: %{map: {:b, :d}}}

      expected_response_body =
        ~S(%Protocol.UndefinedError{description: "Jason.Encoder protocol must always be explicitly implemented", protocol: Jason.Encoder, value: {:b, :d}})

      assert %{
               "response_body" => ^expected_response_body
             } =
               request
               |> BodyBuilder.call()
               |> Jason.decode!()
    end

    test """
           when request has response_body and it's a string, returns it on body
         """,
         %{request: request} do
      expected_response_body = "time_out"

      request = %Request{request | response_body: expected_response_body}

      assert %{"response_body" => ^expected_response_body} =
               request
               |> BodyBuilder.call()
               |> Jason.decode!()
    end

    test """
           when request has response_headers, returns it on body as string
         """,
         %{request: request} do
      request = %Request{request | response_headers: ["Content-Type": "application/json"]}

      expected_response_headers = ~S({"Content-Type":"application/json"})

      assert %{"response_headers" => ^expected_response_headers} =
               request
               |> BodyBuilder.call()
               |> Jason.decode!()
    end

    test """
           when there is invalid data on response_headers,
           returns response_headers with error
         """,
         %{request: request} do
      request = %Request{request | request_headers: %{map: {:b, :d}}}

      expected_request_headers =
        ~S(%Protocol.UndefinedError{description: "Jason.Encoder protocol must always be explicitly implemented", protocol: Jason.Encoder, value: {:b, :d}})

      assert %{
               "request_headers" => ^expected_request_headers
             } =
               request
               |> BodyBuilder.call()
               |> Jason.decode!()
    end

    test """
           when request has response_time, returns it on body as string
         """,
         %{request: request} do
      expected_response_time = "1000ms"

      request = %Request{request | response_time: expected_response_time}

      assert %{"response_time" => ^expected_response_time} =
               request
               |> BodyBuilder.call()
               |> Jason.decode!()
    end

    test """
           when request has status, returns it on body
         """,
         %{request: request} do
      expected_status = 403

      request = %Request{request | status: expected_status}

      assert %{"status" => ^expected_status} =
               request
               |> BodyBuilder.call()
               |> Jason.decode!()
    end

    test """
           when request has type, returns it on body
         """,
         %{request: request} do
      expected_type = "type"

      request = %Request{request | type: expected_type}

      assert %{"type" => ^expected_type} =
               request
               |> BodyBuilder.call()
               |> Jason.decode!()
    end

    test """
           when request has query params, concats it at the end of the url
         """,
         %{request: %Request{url: url} = request} do
      request = %Request{request | query_params: %{banana: true, abacaxi: false}}

      expected_url = "#{url}?abacaxi=false&banana=true"

      assert %{"url" => ^expected_url} =
               request
               |> BodyBuilder.call()
               |> Jason.decode!()
    end

    test """
           when request has not query params, returns the url on body
         """,
         %{request: %Request{url: url} = request} do
      request = %Request{request | query_params: nil}

      assert %{"url" => ^url} =
               request
               |> BodyBuilder.call()
               |> Jason.decode!()
    end
  end
end
