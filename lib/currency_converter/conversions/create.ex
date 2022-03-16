defmodule CurrencyConverter.Conversions.Create do
  @moduledoc """
    Create conversions module.

    Responsible for create the conversion by cleaning the
    incoming parameters and calling each step of the creation
    and processing of a conversion.
  """

  alias CurrencyConverter.{
    Conversion,
    Conversions.Convert,
    ExchangeRates,
    Repo,
    Utils
  }

  alias CurrencyConverter.Conversions.CreateAmount
  alias Ecto.Changeset

  @operation_defined_keys [
    "destination_amount",
    "exchange_rate",
    "processed_at"
  ]

  def call(params) do
    with %Changeset{
           valid?: true
         } = changeset <- create_inicial_changeset(params),
         {:ok, %Conversion{} = conversion} <- Conversion.build(changeset),
         {
           :ok,
           %ExchangeRates{} = exchange_rates
         } <- exchange_rates_client().fetch_exchange_rates(conversion),
         {:ok, conversion_attrs} <- Convert.call(exchange_rates, conversion),
         %Changeset{
           valid?: true
         } = changeset <- Conversion.changeset(conversion, conversion_attrs),
         {:ok, %Conversion{} = conversion} <- Repo.insert(changeset) do
      {:ok, conversion}
    else
      %Changeset{valid?: false} = changeset -> {:error, changeset}
      {:error, _reason} = result -> result
    end
  end

  defp create_inicial_changeset(params) do
    case treat_params(params) do
      {:ok, new_params} -> Conversion.changeset(new_params)
      {:error, _reason} = error -> error
    end
  end

  defp treat_params(params),
    do:
      params
      |> Utils.remove_keys_from_map(@operation_defined_keys)
      |> transform_source_amount()
      |> transform_user_id()
      |> transform_source_currency()
      |> transform_destination_currency()
      |> format_treat_params_return()

  defp transform_source_amount(
         %{
           "source_amount" => source_amount
         } = params
       ) do
    case CreateAmount.call(source_amount) do
      {:ok, %Decimal{} = source_amount} -> Map.put(params, "source_amount", source_amount)
      error -> error
    end
  end

  defp transform_source_amount(params), do: params

  defp transform_user_id(
         %{
           "user_id" => user_id
         } = params
       ),
       do: Map.put(params, "user_id", Utils.value_to_string(user_id))

  defp transform_user_id(params_or_error), do: params_or_error

  defp transform_source_currency(
         %{
           "source_currency" => source_currency
         } = params
       )
       when is_binary(source_currency),
       do: do_transform_currency(params, "source_currency", source_currency)

  defp transform_source_currency(params_or_error), do: params_or_error

  defp transform_destination_currency(
         %{
           "destination_currency" => destination_currency
         } = params
       )
       when is_binary(destination_currency),
       do: do_transform_currency(params, "destination_currency", destination_currency)

  defp transform_destination_currency(params_or_error), do: params_or_error

  defp format_treat_params_return({:error, _reason} = error), do: error
  defp format_treat_params_return(params), do: {:ok, params}

  defp do_transform_currency(params, currency_key, currency),
    do:
      currency
      |> String.upcase()
      |> then(&Map.put(params, currency_key, &1))

  defp exchange_rates_client,
    do:
      Application.get_env(
        :currency_converter,
        :exchange_rates_client,
        CurrencyConverter.ExternalServices.ExchangeRatesApi.Client
      )
end
