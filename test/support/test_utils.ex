defmodule CurrencyConverter.TestUtils do
  alias Plug.Conn

  def endpoint_url(port), do: "http://localhost:#{port}/"

  def headers_in_request_headers?(headers, %Conn{req_headers: request_headers}) do
    Enum.all?(headers, &(&1 in request_headers))
  end
end
