defmodule CurrencyConverter.Error do
  @moduledoc """
    Error module.

    Struct that represents an error to be shown as a request response.
  """

  @type error :: %__MODULE__{
          status: Integer.t() | atom() | nil,
          result: term()
        }

  @keys [:status, :result]

  @enforce_keys @keys

  defstruct @keys

  def build(status, result), do: %__MODULE__{status: status, result: result}
end
