defmodule CurrencyConverterWeb.Plugs.RequestLoggerTest do
  use CurrencyConverterWeb.ConnCase, async: true
  use Plug.Test

  import Mox

  alias CurrencyConverter.Constants.Requests.{Events, Types}
  alias CurrencyConverter.ElasticSearchApi.ClientMock
  alias CurrencyConverter.Request
  alias CurrencyConverterWeb.Plugs.RequestLogger
  alias Plug.Conn

  @request_event Events.get_convert_currency_event()
  @request_type Types.get_received_type()

  setup :verify_on_exit!

  describe "init/1" do
    test "should return the given params" do
      params = [event: @request_event]

      response = RequestLogger.init(params)

      assert response == params
    end
  end

  describe "call/2" do
    test """
      when there is a call with an event in options, call the
      log request from elastic search client with the request
      and returns the response
    """ do
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
          assert method == "POST"
          assert type == @request_type

          {:ok, %{"success" => true}}
        end
      )

      response =
        "POST"
        |> conn("/", %{"id" => 1})
        |> RequestLogger.call(event: @request_event)
        |> Conn.put_resp_header("content-type", "application/json")
        |> Conn.send_resp(200, ~S({"success": true}))

      assert %Plug.Conn{status: 200} = response
    end

    test """
      when there is a call with an event in options and the conn was
      processed by a view, formats the body, calls the
      log request from elastic search client with the request
      and returns the respons
    """ do
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
          assert method == "POST"
          assert type == @request_type

          {:ok, %{"success" => true}}
        end
      )

      response =
        "POST"
        |> conn("/", %{"id" => 1})
        |> RequestLogger.call(event: @request_event)
        |> Conn.put_resp_header("content-type", "application/json")
        |> then(&%Conn{&1 | private: Map.put(&1.private, :phoenix_format, "json")})
        |> Conn.send_resp(200, Jason.encode_to_iodata!(%{"success" => true}))

      assert %Plug.Conn{status: 200} = response
    end

    test """
      when there is a call but the options has no event, doesn't call
      the log request from elastic search client with the request
      and returns the response
    """ do
      expect(ClientMock, :log_request, 0, fn _ -> {:ok, %{"success" => true}} end)

      response =
        "POST"
        |> conn("/", %{"id" => 1})
        |> RequestLogger.call([])
        |> Conn.put_resp_header("content-type", "application/json")
        |> Conn.send_resp(200, ~S({"success": true}))

      assert %Plug.Conn{status: 200} = response
    end
  end
end
