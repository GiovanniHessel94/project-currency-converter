defmodule CurrencyConverterWeb.PaginationViewTest do
  use CurrencyConverterWeb.ConnCase, async: true

  import Phoenix.View, only: [render: 3]

  alias CurrencyConverterWeb.PaginationView

  test "renders the pagination view" do
    pagination_param = %{
      pagination: %{
        "page" => 1,
        "limit" => 5,
        "order_direction" => :asc
      }
    }

    response = render(PaginationView, "pagination.json", pagination_param)

    expected_response = %{limit: 5, order_direction: :asc, page: 1}

    assert response == expected_response
  end
end
