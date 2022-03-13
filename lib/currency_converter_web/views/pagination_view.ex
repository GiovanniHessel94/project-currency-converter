defmodule CurrencyConverterWeb.PaginationView do
  use CurrencyConverterWeb, :view

  def render(
        "pagination.json",
        %{
          pagination: %{
            "page" => page,
            "limit" => limit,
            "order_direction" => order_direction
          }
        }
      ),
      do: %{
        page: page,
        limit: limit,
        order_direction: order_direction
      }
end
