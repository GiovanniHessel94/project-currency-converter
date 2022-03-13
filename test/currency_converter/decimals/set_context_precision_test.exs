defmodule CurrencyConverter.Decimals.SetContextPrecisionTest do
  use ExUnit.Case, async: true

  alias CurrencyConverter.Decimals.SetContextPrecision

  describe "call/0" do
    test "sets the decimal context precision to 38" do
      SetContextPrecision.call()

      %Decimal.Context{precision: 38} = Decimal.Context.get()
    end
  end
end
