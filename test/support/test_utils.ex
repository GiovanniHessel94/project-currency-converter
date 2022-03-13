defmodule CurrencyConverter.TestUtils do
  alias Plug.Conn

  import CurrencyConverter.Factory

  def endpoint_url(port), do: "http://localhost:#{port}/"

  def headers_in_request_headers?(headers, %Conn{req_headers: request_headers}) do
    Enum.all?(headers, &(&1 in request_headers))
  end

  def query_params_in_request_query_params?(
        query_params,
        %Conn{
          query_params: request_query_params
        }
      ),
      do:
        query_params
        |> Map.keys()
        |> Enum.all?(&(Map.get(query_params, &1) == Map.get(request_query_params, &1)))

  def create_conversions_for_user_id(user_id) do
    yesterday_datetime = DateTime.utc_now() |> DateTime.add(-86_400)
    tomorrow_datetime = DateTime.utc_now() |> DateTime.add(86_400)

    first_conversion = insert(:conversion, user_id: user_id, processed_at: yesterday_datetime)
    insert(:conversion, user_id: user_id)
    insert(:conversion, user_id: user_id)
    last_conversion = insert(:conversion, user_id: user_id, processed_at: tomorrow_datetime)

    [first_conversion, last_conversion]
  end
end
