defmodule CurrencyConverter.ElasticSearchApi.ExternalService do
  @moduledoc """
    Elastic search api external service.

    Responsible for all the retry and fuse options used
    on the elastic search api. It also set headers
    used by all the requests.
  """

  alias CurrencyConverter.{
    ElasticSearchApi.ResponseHandler,
    ExternalRequest,
    ExternalServices.Behavior,
    Request,
    Utils
  }

  @behaviour Behavior

  @default_fuse_strategy {:standard, 10, 1_000}

  @fuse_options [
    # Tolerate 10 failures for every 1 second time window when the default value is used.
    fuse_strategy: Utils.get_env(:fuse_strategy, @default_fuse_strategy),
    # Reset the fuse 2.5 seconds after it is blown.
    fuse_refresh: 2_500,
    # Limit to 100 calls per second.
    rate_limit: {100, 1_000}
  ]

  @retry_opts %ExternalService.RetryOptions{
    # Use exponential backoff with the initial delay of 100ms.
    backoff: {:exponential, 50},
    # Limits the time betweeb retries do 1.5 seconds.
    cap: 1500,
    # Stop retrying after 5 seconds.
    expiry: 5_000,
    # Indicates that delays should not be randomized.
    randomize: false,
    # Do not retry on any exception.
    rescue_only: []
  }

  @default_headers ["kbn-xsrf": true]

  @impl Behavior
  def start, do: ExternalService.start(__MODULE__, @fuse_options)

  @impl Behavior
  def request(%Request{} = request),
    do:
      request
      |> put_default_headers()
      |> ExternalRequest.call(__MODULE__, @retry_opts)
      |> ResponseHandler.call()

  defp put_default_headers(
         %Request{
           request_headers: request_headers
         } = request
       ),
       do: %Request{request | request_headers: get_default_headers() ++ request_headers}

  def get_default_headers do
    credentials = Base.encode64("#{get_username()}:#{get_password()}")

    [Authorization: "Basic #{credentials}"] ++ @default_headers
  end

  def get_username, do: Utils.get_env("ELASTIC_SEARCH_API_USERNAME")
  def get_password, do: Utils.get_env("ELASTIC_SEARCH_API_PASSWORD")
end
