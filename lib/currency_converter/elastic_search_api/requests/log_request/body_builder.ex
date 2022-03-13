defmodule CurrencyConverter.ElasticSearchApi.Requests.LogRequests.BodyBuilder do
  @moduledoc """
    Log request body build module.

    Responsible building the body that will be sent
    on the log request operation.
  """

  alias CurrencyConverter.Request

  def call(%Request{} = request),
    do:
      request
      |> do_build_body()
      |> Jason.encode()
      |> elem(1)

  defp do_build_body(%Request{
         event: event,
         method: method,
         options: options,
         query_params: query_params,
         request_body: request_body,
         request_headers: request_headers,
         response_body: response_body,
         response_headers: response_headers,
         response_time: response_time,
         status: status,
         type: type,
         url: url
       }) do
    %{
      processed_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      event: event,
      method: String.downcase(method),
      options: encode_data(options),
      request_body: encode_data(request_body),
      request_headers: encode_data(request_headers),
      response_body: encode_data(response_body),
      response_headers: encode_data(response_headers),
      response_time: response_time,
      status: status,
      type: type,
      url: format_url(url, query_params)
    }
  end

  defp encode_data(data) when data in [nil, ""], do: "{}"

  defp encode_data(data) when is_binary(data), do: data

  defp encode_data(data) when is_map(data), do: do_encode_data(data)

  defp encode_data(data) when is_list(data),
    do:
      data
      |> Map.new()
      |> do_encode_data()

  defp do_encode_data(data) do
    case Jason.encode(data) do
      {:ok, data_string} -> data_string
      {:error, reason} -> inspect(reason)
    end
  end

  defp format_url(url, query_params) when query_params in [nil, %{}], do: url
  defp format_url(url, query_params), do: "#{url}?#{format_query_params(query_params)}"

  defp format_query_params(query_params) do
    query_params
    |> Map.to_list()
    |> Enum.reduce("", fn {key, value}, acc ->
      query_param = "#{key}=#{value}"

      if acc == "", do: query_param, else: "#{acc}&#{query_param}"
    end)
  end
end
