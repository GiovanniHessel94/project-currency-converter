Mox.defmock(
  CurrencyConverter.ElasticSearchApi.ClientMock,
  for: CurrencyConverter.ElasticSearchApi.Behavior
)

Application.put_env(
  :currency_converter,
  :elastic_search_client,
  CurrencyConverter.ElasticSearchApi.ClientMock
)

Mox.defmock(
  CurrencyConverter.ExchangeRatesApi.ClientMock,
  for: CurrencyConverter.ExchangeRatesApi.Behavior
)

Application.put_env(
  :currency_converter,
  :exchange_rates_client,
  CurrencyConverter.ExchangeRatesApi.ClientMock
)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(CurrencyConverter.Repo, :manual)
