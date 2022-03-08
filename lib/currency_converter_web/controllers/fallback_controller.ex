defmodule CurrencyConverterWeb.FallbackController do
  use CurrencyConverterWeb, :controller

  alias CurrencyConverter.Error
  alias CurrencyConverterWeb.ErrorView
  alias Ecto.Changeset

  def call(
        conn,
        {:error, %Error{status: status, result: result}}
      ),
      do: render_view(conn, status, result)

  def call(
        conn,
        {:error, %Changeset{} = changeset}
      ),
      do: render_view(conn, :bad_request, changeset)

  defp render_view(conn, status, result),
    do:
      conn
      |> put_status(status)
      |> put_view(ErrorView)
      |> render("error.json", result: result)
end
