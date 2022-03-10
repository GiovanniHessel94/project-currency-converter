defmodule CurrencyConverter.UtilsTest do
  use ExUnit.Case, async: true

  alias CurrencyConverter.Utils

  describe "format_microseconds/1" do
    test """
      when microseconds are equal or greater than
      1000, format it as a milliseconds string
    """ do
      microseconds = 1000

      response = Utils.format_microseconds(microseconds)

      expected_response = "1ms"

      assert response == expected_response
    end

    test "when microseconds are less than 1000, format it as a microseconds string" do
      microseconds = 999

      response = Utils.format_microseconds(microseconds)

      expected_response = "999µs"

      assert response == expected_response
    end
  end
end
