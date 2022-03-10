defmodule CurrencyConverter.Request do
  @required_keys [
    :method,
    :type,
    :url
  ]

  @keys [
    :event,
    :method,
    :response_time,
    :status,
    :type,
    :url,
    log_request: true,
    options: [],
    query_params: %{},
    request_body: "",
    request_headers: [],
    response_body: "",
    response_headers: []
  ]

  @enforce_keys @required_keys

  defstruct @keys
end
