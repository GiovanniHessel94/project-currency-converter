defmodule CurrencyConverterWeb.Plugs.Paginator do
  @moduledoc """
    Paginator plug.

    Responsible for validating and injecting pagination data.
  """

  import CurrencyConverterWeb.ErrorHelpers
  import Plug.Conn

  alias CurrencyConverter.Pagination
  alias Ecto.Changeset
  alias Plug.Conn

  def init(opts), do: opts

  def call(%Conn{params: params} = conn, _opts) do
    with %Changeset{valid?: true} = changeset <- call_changeset(params),
         pagination_data <- Pagination.extract_data(changeset) do
      new_params = Map.merge(params, pagination_data)

      %Conn{conn | params: new_params}
    else
      %Changeset{valid?: false} = changeset -> handle_changeset_error(changeset, conn)
    end
  end

  defp call_changeset(params),
    do:
      params
      |> transform_order_direction()
      |> then(&Pagination.changeset(%Pagination{}, &1))

  defp transform_order_direction(
         %{
           "order_direction" => order_direction
         } = params
       )
       when is_binary(order_direction),
       do:
         order_direction
         |> String.downcase()
         |> String.to_atom()
         |> then(&Map.put(params, "order_direction", &1))

  defp transform_order_direction(params), do: params

  defp handle_changeset_error(changeset, conn) do
    body =
      Jason.encode!(%{
        success: false,
        reason: "invalid params",
        errors: translate_errors(changeset)
      })

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(:bad_request, body)
    |> halt()
  end
end
