defmodule CurrencyConverter.Constants.Requests.Events do
  @moduledoc """
    Constants of all available request events.
  """

  @convert_currency_event "convert_currency"
  @fetch_exchange_rates_event "fetch_exchange_rates"

  @available_events [
    @convert_currency_event,
    @fetch_exchange_rates_event
  ]

  def get_convert_currency_event, do: @convert_currency_event
  def get_fetch_exchange_rates_event, do: @fetch_exchange_rates_event
  def get_available_events, do: @available_events
end
