defmodule CurrencyConverterWeb.ErrorHelpers do
  @moduledoc """
    Conveniences for translating and building error messages.
  """
  import Ecto.Changeset, only: [traverse_errors: 2]

  alias Ecto.Changeset

  @doc """
    Translates the errors of a changeset.
  """
  @spec translate_errors(Changeset.t()) :: map()
  def translate_errors(%Changeset{} = changeset) do
    traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", translate_value(value))
      end)
    end)
  end

  defp translate_value({:parameterized, Ecto.Enum, _map}), do: ""
  defp translate_value(value), do: to_string(value)
end
