defmodule CurrencyConverter.Conversions.Get do
  @moduledoc """
    Get conversions module.

    Responsible for fetching the conversions
    data from the database according to the
    incoming params.
  """

  import Ecto.Query, only: [from: 2]

  alias CurrencyConverter.{Conversion, Repo}

  def by_user_id(params),
    do:
      params
      |> by_user_id_query()
      |> Repo.all()
      |> then(&{:ok, &1})

  defp by_user_id_query(%{
         "user_id" => user_id,
         "limit" => limit,
         "offset" => offset,
         "order_direction" => order_direction
       }) do
    order_by_clausule = [{order_direction, :processed_at}]

    from conversion in Conversion,
      where: conversion.user_id == ^user_id,
      order_by: ^order_by_clausule,
      limit: ^limit,
      offset: ^offset
  end
end
