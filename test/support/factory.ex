defmodule CurrencyConverter.Factory do
  use ExMachina.Ecto, repo: CurrencyConverter.Repo

  alias CurrencyConverter.{Conversion, Pagination}

  def conversion_factory do
    %Conversion{
      user_id: Ecto.UUID.generate(),
      source_currency: "BRL",
      source_amount: Decimal.new("10.00000"),
      destination_currency: "USD",
      exchange_rate:
        1..100
        |> Enum.random()
        |> Decimal.new()
        |> Decimal.round(5),
      processed_at: DateTime.utc_now()
    }
  end

  def pagination_factory do
    %Pagination{
      page: 1,
      limit: 25,
      order_direction: :desc
    }
  end
end
