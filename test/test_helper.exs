Mox.defmock(
  CurrencyConverter.ElasticSearchApi.ClientMock,
  for: CurrencyConverter.ElasticSearchApi.Behavior
)

Application.put_env(
  :currency_converter,
  :elastic_search_client,
  CurrencyConverter.ElasticSearchApi.ClientMock
)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(CurrencyConverter.Repo, :manual)
