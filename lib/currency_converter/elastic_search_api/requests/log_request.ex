defmodule CurrencyConverter.ElasticSearchApi.Requests.LogRequest do
  alias CurrencyConverter.ElasticSearchApi.{
    ExternalService,
    Requests.LogRequests.BodyBuilder
  }

  alias CurrencyConverter.Constants.Requests.{Events, Types}
  alias CurrencyConverter.{Error, Request}

  @available_events Events.get_available_events()
  @available_types Types.get_available_types()

  @external_type Types.get_external_type()

  @request %Request{
    log_request: false,
    method: "POST",
    request_headers: ["Content-Type": "application/json"],
    type: @external_type,
    url: ""
  }

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
        |> Map.put(:url, "#{url}requests/_doc")
        |> ExternalService.request()
        |> handle_request()

  def call(
        _url,
        _request_to_log
      ),
      do: {:error, Error.build(:unprocessable_entity, "Invalid request")}

  defp handle_request({:ok, %HTTPoison.Response{body: body}}), do: {:ok, body}
  defp handle_request({:error, _reason} = result), do: result
end
