defmodule CurrencyConverter.ExternalServices.ExchangeRatesApi.ResponseHandler do
  @moduledoc """
    Exchange rates api response handler.

    Responsible for handling the responses from the
    exchange rates api.
  """

  alias CurrencyConverter.Error

  @service_unavailable_message "service unavailable"
  @generic_error_message "an error occurred while communicating with the exchange rates api"

  def call({:ok, %HTTPoison.Response{status_code: status_code}} = result)
      when status_code in 200..299,
      do: result

  def call({:ok, %HTTPoison.Response{body: body}}), do: handle_error_response(body)

  def call({:error, %Error{}} = result), do: result

  def call({:error, %HTTPoison.Error{}}),
    do: {:error, Error.build(:service_unavailable, @service_unavailable_message)}

  defp handle_error_response(%{
         "error" => %{
           "message" => message
         }
       }),
       do: {
         :error,
         Error.build(
           :unprocessable_entity,
           "#{@generic_error_message}. #{String.downcase(message)}"
         )
       }

  defp handle_error_response(_body),
    do: {
      :error,
      Error.build(:unprocessable_entity, @generic_error_message)
    }
end
