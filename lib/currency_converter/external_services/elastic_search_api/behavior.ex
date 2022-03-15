defmodule CurrencyConverter.ExternalServices.ElasticSearchApi.Behavior do
  @moduledoc """
    Elastic search api client behavior.

    Responsible for defining the behaviors of the elastic search api client.
  """

  alias CurrencyConverter.{Error, Request}

  @callback log_request(Request.t()) :: {:ok, term()} | {:error, Error.t()}
end
