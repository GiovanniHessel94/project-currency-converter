defmodule CurrencyConverter.ElasticSearchApi.ExternalService do
  alias CurrencyConverter.ElasticSearchApi.ResponseHandler
  alias CurrencyConverter.{ExternalRequest, Request}
  alias CurrencyConverter.ExternalRequests.Behavior

  @behaviour Behavior

  @fuse_options [
    # Tolerate 10 failures for every 1 second time window.
    fuse_strategy: {:standard, 10, 1_000},
    # Reset the fuse 2.5 seconds after it is blown.
    fuse_refresh: 2_500,
    # Limit to 50 calls per second.
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

  @username System.get_env("ELASTIC_SEARCH_USERNAME")
  @password System.get_env("ELASTIC_SEARCH_PASSWORD")
  @credentials Base.encode64("#{@username}:#{@password}")

  @default_headers [
    Authorization: "Basic #{@credentials}",
    "kbn-xsrf": true
  ]

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
       do: %Request{request | request_headers: @default_headers ++ request_headers}
end
