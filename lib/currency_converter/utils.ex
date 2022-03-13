defmodule CurrencyConverter.Utils do
  @moduledoc """
    Utils module.

    Contains functions shared in the app.
  """

  def format_microseconds(microseconds) when microseconds >= 1000,
    do:
      microseconds
      |> div(1000)
      |> Integer.to_string()
      |> then(fn milliseconds -> "#{milliseconds}ms" end)

  def format_microseconds(microseconds),
    do:
      microseconds
      |> Integer.to_string()
      |> then(fn microseconds -> "#{microseconds}µs" end)

  def remove_keys_from_map(%{} = map, keys), do: Enum.reduce(keys, map, &Map.delete(&2, &1))

  def value_to_string(value) do
    to_string(value)
  rescue
    _e in [Protocol.UndefinedError] -> inspect(value)
  end

  def get_env(env_name, default \\ nil)

  def get_env(env_name, default) when is_binary(env_name) do
    env_name_atom =
      env_name
      |> String.downcase()
      |> String.to_atom()

    do_get_env(env_name, env_name_atom, default)
  end

  def get_env(env_name, default) when is_atom(env_name) do
    env_name_string =
      env_name
      |> Atom.to_string()
      |> String.upcase()

    do_get_env(env_name_string, env_name, default)
  end

  defp do_get_env(env_string, env_atom, default) do
    System.get_env(env_string) || Application.get_env(:currency_converter, env_atom) || default
  end
end
