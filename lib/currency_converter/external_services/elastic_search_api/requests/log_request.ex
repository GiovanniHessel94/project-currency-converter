defmodule CurrencyConverter.ExternalServices.ElasticSearchApi.Requests.LogRequest do
  @moduledoc """
    Log request operation module.

    Responsible for handling the log request operation.
  """

  alias CurrencyConverter.{
    Constants.Requests,
    Error,
    ExternalServices.ElasticSearchApi,
    Request
  }

  alias ElasticSearchApi.{ExternalService, Requests.LogRequests.BodyBuilder}
  alias Requests.{Events, Types}

  @external_type Types.get_external_type()

  @request %Request{
    log_request: false,
    method: "POST",
    request_headers: ["Content-Type": "application/json"],
    type: @external_type
  }

  @available_events Events.get_available_events()
  @available_types Types.get_available_types()

  @invalid_request_message "request has an invalid event or type, or log request is false"

  def call(
        url,
        %Request{
          event: event,
          log_request: true,
          type: type
        } = request_to_log
      )
      when event in @available_events and type in @available_types,
      do:
        @request
        |> Map.put(:request_body, BodyBuilder.call(request_to_log))
        |> Map.put(:url, "#{url}requests-logs/_doc")
        |> ExternalService.request()
        |> handle_request()

  def call(
        _url,
        _request_to_log
      ),
      do: {:error, Error.build(:unprocessable_entity, @invalid_request_message)}

  defp handle_request({:ok, %HTTPoison.Response{body: body}}), do: {:ok, body}
  defp handle_request({:error, _reason} = result), do: result
end
