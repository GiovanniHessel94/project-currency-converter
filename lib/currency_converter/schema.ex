defmodule CurrencyConverter.Schema do
  @moduledoc """
    Base schema with system wide configurations to be shared between non embedded schemas.
  """

  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
      @timestamps_opts [inserted_at: :created_at, type: :utc_datetime_usec]
    end
  end
end
