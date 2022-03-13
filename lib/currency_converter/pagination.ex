defmodule CurrencyConverter.Pagination do
  @moduledoc """
    pagination module.

    Schema that represents the conversion
    and apply it's validations.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset

  @type pagination :: %__MODULE__{
          page: Integer.t() | nil,
          limit: Integer.t() | nil,
          order_direction: :asc | :desc | nil
        }

  @keys [
    :page,
    :limit,
    :order_direction
  ]

  @accepted_orders_by [:asc, :desc]

  @primary_key false
  embedded_schema do
    field :page, :integer
    field :limit, :integer, default: 25
    field :order_direction, Ecto.Enum, values: @accepted_orders_by, default: :desc
  end

  def changeset(pagination \\ %__MODULE__{}, params),
    do:
      pagination
      |> cast(params, @keys)
      |> validate_required(@keys)
      |> validate_number(:page, greater_than_or_equal_to: 1)
      |> validate_number(:limit, greater_than_or_equal_to: 1, less_than_or_equal_to: 500)

  def extract_data(%Changeset{valid?: true} = changeset) do
    page = get_field(changeset, :page)
    limit = get_field(changeset, :limit)
    order_direction = get_field(changeset, :order_direction)

    %{
      "page" => page,
      "limit" => limit,
      "offset" => limit * (page - 1),
      "order_direction" => order_direction
    }
  end
end
