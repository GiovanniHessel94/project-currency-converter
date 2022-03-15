defmodule CurrencyConverter.ExternalServices.ExchangeRatesApi.Requests.FetchExchangeRates do
  @moduledoc """
    fetch exchange rates operation module.

    Responsible for handling the fetch exchange rates operation.
  """

  alias CurrencyConverter.{
    Constants.Currencies,
    Constants.Requests,
    Conversion,
    Error,
    ExternalServices.ExchangeRatesApi,
    Request
  }

  alias Requests.{Events, Types}
  alias ExchangeRatesApi.{ExternalService, Requests.FetchExchangeRates.ResponseBuilder}

  @fetch_exchange_rates_event Events.get_fetch_exchange_rates_event()
  @external_type Types.get_external_type()

  @request %Request{
    event: @fetch_exchange_rates_event,
    method: "GET",
    type: @external_type,
    query_params: %{base: "EUR"}
  }

  @available_currencies Currencies.get_available_currencies()

  @invalid_params_message "invalid source currency or destination currency"

  def call(
        url,
        %Conversion{
          source_currency: source_currency,
          destination_currency: destination_currency
        } = conversion
      )
      when source_currency in @available_currencies and
             destination_currency in @available_currencies,
      do:
        @request
        |> Map.put(:url, "#{url}v1/latest")
        |> put_query_params(conversion)
        |> ExternalService.request()
        |> handle_request()

  def call(
        _url,
        _conversion
      ),
      do: {:error, Error.build(:unprocessable_entity, @invalid_params_message)}

  defp put_query_params(
         %Request{
           query_params: query_params
         } = request,
         %Conversion{
           source_currency: source_currency,
           destination_currency: destination_currency
         }
       ) do
    new_query_params =
      Map.put(
        query_params,
        :symbols,
        "#{source_currency},#{destination_currency}"
      )

    %Request{request | query_params: new_query_params}
  end

  defp handle_request({:ok, %HTTPoison.Response{body: body}}), do: ResponseBuilder.call(body)
  defp handle_request({:error, _reason} = result), do: result
end
