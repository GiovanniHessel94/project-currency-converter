defmodule CurrencyConverter.Utils do
  def format_microseconds(microseconds) when microseconds >= 1000,
    do:
      microseconds
      |> div(1000)
      |> Integer.to_string()
      |> then(fn milliseconds -> "#{milliseconds}ms" end)

  def format_microseconds(microseconds),
    do:
      microseconds
      |> Integer.to_string()
      |> then(fn microseconds -> "#{microseconds}µs" end)
end
