defmodule CurrencyConverter.ElasticSearchApi.Client do
  alias CurrencyConverter.ElasticSearchApi.{
    Behavior,
    Requests.LogRequest
  }

  @behaviour Behavior

  @base_url System.get_env("ELASTIC_SEARCH_BASE_URL")

  def log_request(request), do: LogRequest.call(@base_url, request)
end
