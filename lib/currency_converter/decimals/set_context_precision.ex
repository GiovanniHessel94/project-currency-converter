defmodule CurrencyConverter.Decimals.SetContextPrecision do
  @moduledoc """
    Set decimal context precision module.

    Responsible setting the precision of the decimal to 38.
  """

  alias Decimal.Context

  def call, do: Context.set(%Context{Context.get() | precision: 38})
end
