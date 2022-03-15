defmodule CurrencyConverter.ExternalServices.ElasticSearchApi.Client do
  @moduledoc """
    Elastic search api client.

    Responsible for grouping all the operations
    performed in the elastic search api.
  """

  alias CurrencyConverter.{ExternalServices.ElasticSearchApi, Utils}
  alias ElasticSearchApi.{Behavior, Requests.LogRequest}

  @behaviour Behavior

  @impl true
  def log_request(request), do: do_log_request(request, get_service_enabled())

  def do_log_request(
        request,
        service_enabled?
      )
      when service_enabled? in [true, "true"],
      do: LogRequest.call(get_base_url(), request)

  def do_log_request(_request, _service_enabled?), do: {:ok, "elastic search disabled"}

  def get_base_url, do: Utils.get_env("ELASTIC_SEARCH_API_BASE_URL")
  def get_service_enabled, do: Utils.get_env("ELASTIC_SEARCH_API_ENABLED")
end
