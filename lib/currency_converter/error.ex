defmodule CurrencyConverter.Error do
  @moduledoc """
    Struct that represents an error to be shown as a request response.
  """

  @keys [:status, :result]

  @enforce_keys @keys

  defstruct @keys

  def build(status, result), do: %__MODULE__{status: status, result: result}
end
