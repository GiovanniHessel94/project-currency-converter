defmodule CurrencyConverter.Conversion do
  @moduledoc """
    Conversion module.

    Schema that represents the conversion
    and apply it's validations.
  """

  use CurrencyConverter.Schema

  import Ecto.Changeset

  alias CurrencyConverter.Constants.Currencies
  alias Ecto.Changeset

  @type conversion :: %__MODULE__{
          user_id: String.t(),
          source_currency: String.t(),
          source_amount: Decimal.t(),
          destination_currency: String.t(),
          destination_amount: Decimal.t() | nil,
          exchange_rate: Decimal.t() | nil,
          processed_at: DateTime.t() | nil,
          id: Ecto.UUID.t() | nil,
          created_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @required_keys [:user_id, :source_currency, :source_amount, :destination_currency]
  @keys [:destination_amount, :exchange_rate, :processed_at] ++ @required_keys

  @available_currencies Currencies.get_available_currencies()

  @currencies_cant_be_equal_error "source and destination currencies can not be the same"
  @user_id_format_error "user id must be a positive integer or an UUID"

  schema "conversions" do
    field :user_id, :string
    field :source_currency, :string
    field :source_amount, :decimal
    field :destination_currency, :string
    field :destination_amount, :decimal, virtual: true
    field :exchange_rate, :decimal
    field :processed_at, :utc_datetime_usec

    timestamps()
  end

  def build(%Changeset{} = changeset), do: apply_action(changeset, :create)

  def changeset(conversion \\ %__MODULE__{}, params),
    do:
      conversion
      |> cast(params, @keys)
      |> validate_required(@required_keys)
      |> handle_user_id()
      |> validate_inclusion(:source_currency, @available_currencies)
      |> validate_number(:source_amount, greater_than_or_equal_to: 0)
      |> validate_inclusion(:destination_currency, @available_currencies)
      |> validate_number(:destination_amount, greater_than_or_equal_to: 0)
      |> validate_number(:exchange_rate, greater_than_or_equal_to: 0)
      |> validate_currencies_cant_be_equal()
      |> check_constraint(:source_amount, name: :source_amount_must_be_positive)
      |> check_constraint(:exchange_rate, name: :exchange_rate_must_be_positive)

  def handle_user_id(%Changeset{} = changeset) do
    user_id = get_field(changeset, :user_id)

    {changeset, user_id}
    |> handle_uuid_user_id()
    |> handle_integer_user_id()
    |> put_user_id_format_error()
  end

  defp validate_currencies_cant_be_equal(%Changeset{} = changeset) do
    source_currency = get_field(changeset, :source_currency)
    destination_currency = get_field(changeset, :destination_currency)

    put_currencies_cant_be_equal_error(changeset, source_currency, destination_currency)
  end

  defp handle_uuid_user_id({_changeset, nil} = params), do: params

  defp handle_uuid_user_id({changeset, user_id}) do
    case Ecto.UUID.cast(user_id) do
      :error -> {changeset, user_id}
      _uuid -> {changeset, :uuid}
    end
  end

  defp handle_integer_user_id({_changeset, user_id_or_type_atom} = params)
       when user_id_or_type_atom in [nil, :uuid],
       do: params

  defp handle_integer_user_id({changeset, user_id}) do
    with {value, ""} <- Integer.parse(user_id),
         true <- value > 0 do
      new_changeset = put_change(changeset, :user_id, to_string(value))

      {new_changeset, :integer}
    else
      _ -> {changeset, user_id}
    end
  end

  defp put_user_id_format_error({changeset, user_id_or_type_atom})
       when user_id_or_type_atom in [:uuid, :integer],
       do: changeset

  defp put_user_id_format_error({changeset, _id}),
    do:
      add_error(
        changeset,
        :user_id,
        @user_id_format_error,
        validation: :invalid_user_id_format
      )

  defp put_currencies_cant_be_equal_error(
         changeset,
         source_currency,
         destination_currency
       )
       when source_currency == destination_currency and source_currency in @available_currencies,
       do:
         changeset
         |> add_error(
           :source_currency,
           @currencies_cant_be_equal_error,
           validation: :invalid_currencies
         )
         |> add_error(
           :destination_currency,
           @currencies_cant_be_equal_error,
           validation: :invalid_currencies
         )

  defp put_currencies_cant_be_equal_error(
         changeset,
         _source_currency,
         _destination_currency
       ),
       do: changeset
end
