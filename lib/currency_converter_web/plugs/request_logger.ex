defmodule CurrencyConverterWeb.Plugs.RequestLogger do
  import Plug.Conn

  alias CurrencyConverter.Constants.Requests.{Events, Types}
  alias CurrencyConverter.ElasticSearchApi.Client
  alias CurrencyConverter.{Request, Utils}
  alias Plug.Conn

  @available_events Events.get_available_events()
  @request_type Types.get_received_type()

  def init(opts), do: opts

  def call(%Conn{} = conn, event: event) do
    request = create_request_struct(conn, event)

    start_time = System.monotonic_time()

    register_before_send(conn, &handle_before_send(&1, request, start_time))
  end

  def call(%Conn{} = conn, _opts), do: conn

  defp create_request_struct(
         %Conn{
           method: method,
           body_params: request_body,
           req_headers: request_headers,
           host: host,
           request_path: request_path,
           query_params: query_params
         },
         event
       )
       when event in @available_events do
    %Request{
      event: event,
      method: method,
      query_params: query_params,
      request_body: request_body,
      request_headers: request_headers,
      type: @request_type,
      url: "#{host}#{request_path}"
    }
  end

  defp handle_before_send(
         %Conn{
           status: status,
           resp_body: response_body,
           resp_headers: response_headers
         } = conn,
         %Request{} = request,
         start_time
       ) do
    request
    |> Map.put(:response_time, calculate_response_time(start_time))
    |> Map.put(:status, status)
    |> Map.put(:response_body, response_body)
    |> Map.put(:response_headers, response_headers)
    |> log_request()

    conn
  end

  defp log_request(%Request{} = request) do
    client = elastic_search_client()

    case client do
      Client -> Task.start(fn -> client.log_request(request) end)
      _ -> client.log_request(request)
    end
  end

  defp calculate_response_time(start_time),
    do:
      (System.monotonic_time() - start_time)
      |> System.convert_time_unit(:native, :microsecond)
      |> Utils.format_microseconds()

  defp elastic_search_client,
    do:
      Application.get_env(
        :currency_converter,
        :elastic_search_client,
        CurrencyConverter.ElasticSearchApi.Client
      )
end
