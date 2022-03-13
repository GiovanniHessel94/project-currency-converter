defmodule CurrencyConverter.ExchangeRatesApi.ExternalService do
  @moduledoc """
    Exchange rates api external service.

    Responsible for all the retry and fuse options used
    on the exchange rates api. It also set query params
    used by all the requests.
  """

  alias CurrencyConverter.{
    ExchangeRatesApi.ResponseHandler,
    ExternalRequest,
    ExternalServices.Behavior,
    Request,
    Utils
  }

  @behaviour Behavior

  @default_fuse_strategy {:standard, 5, 1_000}

  @fuse_options [
    # Tolerate 5 failures for every 1 second time window when the default value is used.
    fuse_strategy: Utils.get_env(:fuse_strategy, @default_fuse_strategy),
    # Reset the fuse 2.5 seconds after it is blown.
    fuse_refresh: 2_500,
    # Limit to 50 calls per second.
    rate_limit: {50, 1_000}
  ]

  @retry_opts %ExternalService.RetryOptions{
    # Use exponential backoff with the initial delay of 100ms.
    backoff: {:exponential, 100},
    # Limits the time betweeb retries do 1.5 seconds.
    cap: 1500,
    # Stop retrying after 5 seconds.
    expiry: 5_000,
    # Indicates that delays should not be randomized.
    randomize: false,
    # Do not retry on any exception.
    rescue_only: []
  }

  @impl Behavior
  def start, do: ExternalService.start(__MODULE__, @fuse_options)

  @impl Behavior
  def request(%Request{} = request),
    do:
      request
      |> put_default_query_param()
      |> ExternalRequest.call(__MODULE__, @retry_opts)
      |> ResponseHandler.call()

  defp put_default_query_param(
         %Request{
           query_params: query_params
         } = request
       ),
       do: %Request{request | query_params: Map.put(query_params, :access_key, get_acess_key())}

  defp get_acess_key, do: Utils.get_env("EXCHANGE_RATES_API_ACCESS_KEY")
end
