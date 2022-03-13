import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :currency_converter, CurrencyConverter.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "currency_converter_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :currency_converter, CurrencyConverterWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "4wYt5kKPi/1e9bvmkZHayeE5Xzt5G3m863ACPoJ1ngrLDUyo/x3YA8yQ0h8rFO8L",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Configures Exchange Rates API and Elastic Search API fuse strategy on tests.
config :currency_converter, fuse_strategy: {:standard, 500, 1_000}
