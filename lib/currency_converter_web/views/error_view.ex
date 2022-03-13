defmodule CurrencyConverterWeb.ErrorView do
  use CurrencyConverterWeb, :view

  import CurrencyConverterWeb.ErrorHelpers

  alias Ecto.Changeset

  # If you want to customize a particular status code
  # for a certain format, you may uncomment below.
  # def render("500.json", _assigns) do
  #   %{errors: %{detail: "Internal Server Error"}}
  # end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.json" becomes
  # "Not Found".
  def template_not_found(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end

  def render(
        "error.json",
        %{result: %Changeset{} = changeset}
      ),
      do: %{
        success: false,
        reason: "invalid params",
        errors: translate_errors(changeset)
      }

  def render(
        "error.json",
        %{result: result}
      ),
      do: %{
        success: false,
        reason: result
      }
end
