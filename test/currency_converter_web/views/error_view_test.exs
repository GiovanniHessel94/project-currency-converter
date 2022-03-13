defmodule CurrencyConverterWeb.ErrorViewTest do
  use CurrencyConverterWeb.ConnCase, async: true

  import Phoenix.View, only: [render: 3]

  alias CurrencyConverterWeb.ErrorView

  test "renders 404.json" do
    response = render(ErrorView, "404.json", [])

    expected_response = %{errors: %{detail: "Not Found"}}

    assert response == expected_response
  end

  test "renders 500.json" do
    response = render(ErrorView, "500.json", [])

    expected_response = %{errors: %{detail: "Internal Server Error"}}

    assert response == expected_response
  end

  test "when the result is an text, renders it with only success and reason" do
    result_param = %{result: "an error has occurred"}

    response = render(ErrorView, "error.json", result_param)

    expected_response = %{reason: "an error has occurred", success: false}

    assert response == expected_response
  end

  test """
    when the result is an changeset, renders it's
    errors with success, reason and errors
  """ do
    {:error, changeset_with_errors} = CurrencyConverter.create_conversion(%{})

    result_param = %{result: changeset_with_errors}

    response = render(ErrorView, "error.json", result_param)

    expected_response = %{
      reason: "invalid params",
      success: false,
      errors: %{
        destination_currency: ["can't be blank"],
        source_amount: ["can't be blank"],
        source_currency: ["can't be blank"],
        user_id: ["user id must be a positive integer or an UUID", "can't be blank"]
      }
    }

    assert response == expected_response
  end
end
