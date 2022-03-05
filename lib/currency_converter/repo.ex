defmodule CurrencyConverter.Repo do
  use Ecto.Repo,
    otp_app: :currency_converter,
    adapter: Ecto.Adapters.Postgres
end
