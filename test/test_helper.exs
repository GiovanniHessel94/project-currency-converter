Mox.defmock(
  CurrencyConverter.ExternalServices.ElasticSearchApi.ClientMock,
  for: CurrencyConverter.ExternalServices.ElasticSearchApi.Behavior
)

Application.put_env(
  :currency_converter,
  :elastic_search_client,
  CurrencyConverter.ExternalServices.ElasticSearchApi.ClientMock
)

Mox.defmock(
  CurrencyConverter.ExternalServices.ExchangeRatesApi.ClientMock,
  for: CurrencyConverter.ExternalServices.ExchangeRatesApi.Behavior
)

Application.put_env(
  :currency_converter,
  :exchange_rates_client,
  CurrencyConverter.ExternalServices.ExchangeRatesApi.ClientMock
)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(CurrencyConverter.Repo, :manual)
