defmodule CurrencyConverter do
  @moduledoc """
  CurrencyConverter keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  alias CurrencyConverter.Conversions.CalculateDestinationAmount, as: CalculateDestinationAmount
  alias CurrencyConverter.Conversions.Create, as: CreateConversion
  alias CurrencyConverter.Conversions.Get, as: GetConversion

  defdelegate create_conversion(params), to: CreateConversion, as: :call
  defdelegate get_conversion_by_user_id(params), to: GetConversion, as: :by_user_id

  defdelegate calculate_destination_amount(exchange_rate, source_amount),
    to: CalculateDestinationAmount,
    as: :call
end
