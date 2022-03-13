defmodule CurrencyConverter.Constants.Requests.Types do
  @moduledoc """
    Requests types constants.

    Constants of all available request types.
  """

  @received_type "received_request"
  @external_type "external_request"

  @available_types [
    @external_type,
    @received_type
  ]

  def get_received_type, do: @received_type
  def get_external_type, do: @external_type
  def get_available_types, do: @available_types
end
