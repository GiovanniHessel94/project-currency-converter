defmodule CurrencyConverter.Request do
  @moduledoc """
    Request module.

    Struct that represents a request.
  """

  @type request :: %__MODULE__{
          event: String.t() | nil,
          log_request: true | false,
          method: String.t(),
          options: list() | nil,
          query_params: map() | nil,
          request_body: String.t() | map() | nil,
          request_headers: list() | nil,
          response_body: String.t() | map() | nil,
          response_headers: list() | nil,
          response_time: String.t() | nil,
          status: Integer.t() | atom() | nil,
          type: String.t(),
          url: String.t() | nil
        }

  @required_keys [
    :method,
    :type
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
