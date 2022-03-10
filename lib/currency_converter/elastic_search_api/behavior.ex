defmodule CurrencyConverter.ElasticSearchApi.Behavior do
  alias CurrencyConverter.{Error, Request}

  @callback log_request(Request.t()) :: {:ok, term()} | {:error, Error.t()}
end
