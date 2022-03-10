defmodule CurrencyConverter.ElasticSearchApi.ResponseHandler do
  alias CurrencyConverter.Error

  def call({:ok, %HTTPoison.Response{status_code: status_code}} = result)
      when status_code in 200..299,
      do: result

  def call({:ok, %HTTPoison.Response{body: body}}), do: handle_error_response(body)

  def call({:error, %Error{}} = result), do: result

  def call({
        :error,
        %HTTPoison.Error{} = error
      }),
      do: {:error, Error.build(:service_unavailable, HTTPoison.Error.message(error))}

  defp handle_error_response(%{
         "error" => %{"reason" => reason},
         "status" => status
       }),
       do: {:error, Error.build(status, reason)}

  defp handle_error_response(_body),
    do: {
      :error,
      Error.build(:unprocessable_entity, "an error occurred while calling the service")
    }
end
