defmodule CurrencyConverter.ExternalServices.Behavior do
  alias CurrencyConverter.{Error, Request}
  alias HTTPoison.Error, as: PoisonError
  alias HTTPoison.Response

  @callback start() :: :ok

  @callback request(Request.t()) :: {:ok, Response.t()} | {:error, PoisonError.t() | Error.t()}
end
