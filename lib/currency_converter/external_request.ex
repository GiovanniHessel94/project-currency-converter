defmodule CurrencyConverter.ExternalRequest do
  @moduledoc """
    External requests module.

    Responsible for making all the external requests for third party apis.
    It also handles fuse related returns, creates and send requests to be
    logged and 'ungzip' and decode the response body when necessary.
  """

  alias CurrencyConverter.ElasticSearchApi.Client
  alias CurrencyConverter.{Error, Request, Utils}
  alias ExternalService.RetryOptions

  @default_retry_status_codes [
    # TIMEOUT
    408,
    # RESOURCE_EXHAUSTED
    429,
    # CANCELLED
    499,
    # INTERNAL
    500,
    # UNAVAILABLE
    503,
    # DEADLINE_EXCEEDED
    504
  ]

  @rescue_exceptions [
    ExternalService.RetriesExhaustedError,
    ExternalService.FuseBlownError
  ]

  @service_unavailable_message "service unavailable"

  def call(
        %Request{} = request,
        fuse_name,
        %RetryOptions{} = retry_opts,
        retry_status_codes \\ @default_retry_status_codes
      )
      when is_list(retry_status_codes) do
    ExternalService.call!(fuse_name, retry_opts, fn -> do_request(request, retry_status_codes) end)
  rescue
    _e in @rescue_exceptions ->
      {
        :error,
        Error.build(:service_unavailable, @service_unavailable_message)
      }
  end

  defp do_request(
         %Request{
           method: method,
           options: options,
           query_params: query_params,
           request_body: request_body,
           request_headers: request_headers,
           url: url
         } = request,
         retry_status_codes
       ) do
    poison_request = %HTTPoison.Request{
      body: request_body,
      headers: request_headers,
      method: method,
      options: options,
      params: query_params,
      url: url
    }

    fn -> HTTPoison.request(poison_request) end
    |> :timer.tc()
    |> log_request(request)
    |> handle_response(retry_status_codes)
  end

  defp log_request({_response_time, result}, %Request{log_request: false}), do: result

  defp log_request(
         {
           response_time,
           {
             :ok,
             %HTTPoison.Response{
               status_code: status,
               body: response_body,
               headers: response_headers
             }
           } = result
         },
         %Request{} = request
       ) do
    request
    |> Map.put(:response_body, response_body)
    |> Map.put(:response_headers, response_headers)
    |> Map.put(:response_time, Utils.format_microseconds(response_time))
    |> Map.put(:status, status)
    |> do_log_request()

    result
  end

  defp log_request(
         {
           response_time,
           {
             :error,
             %HTTPoison.Error{} = error
           } = result
         },
         %Request{} = request
       ) do
    request
    |> Map.put(:response_body, HTTPoison.Error.message(error))
    |> Map.put(:response_time, Utils.format_microseconds(response_time))
    |> do_log_request()

    result
  end

  defp handle_response(
         {:ok, %HTTPoison.Response{status_code: status_code}} = result,
         retry_status_codes
       ) do
    case status_code in retry_status_codes do
      true -> :retry
      false -> transform_response_body(result)
    end
  end

  defp handle_response({:error, %HTTPoison.Error{}}, _retry_status_codes), do: :retry

  defp do_log_request(%Request{} = request) do
    client = elastic_search_client()

    case client do
      Client ->
        Task.Supervisor.start_child(
          CurrencyConverter.Tasks.Supervisor,
          fn ->
            client.log_request(request)
          end
        )

      _ ->
        client.log_request(request)
    end
  end

  defp transform_response_body({:ok, %HTTPoison.Response{}} = result),
    do:
      result
      |> ungzip_response_body()
      |> decode_response_body()

  defp ungzip_response_body(
         {
           :ok,
           %HTTPoison.Response{headers: headers, body: body} = response
         } = result
       ) do
    gzipped =
      Enum.any?(headers, fn {key, value} ->
        case {String.downcase(key), value} do
          {"content-encoding", "gzip"} -> true
          {"content-encoding", "x-gzip"} -> true
          _ -> false
        end
      end)

    case gzipped do
      true -> {:ok, %HTTPoison.Response{response | body: :zlib.gunzip(body)}}
      false -> result
    end
  end

  defp decode_response_body({
         :ok,
         %HTTPoison.Response{body: body_string} = response
       }) do
    case Jason.decode(body_string) do
      {:ok, body} -> {:ok, %HTTPoison.Response{response | body: body}}
      {:error, _reason} -> {:ok, %HTTPoison.Response{response | body: %{}}}
    end
  end

  defp elastic_search_client,
    do:
      Application.get_env(
        :currency_converter,
        :elastic_search_client,
        CurrencyConverter.ElasticSearchApi.Client
      )
end
