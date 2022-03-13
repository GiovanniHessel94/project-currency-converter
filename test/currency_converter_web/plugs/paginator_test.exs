defmodule CurrencyConverterWeb.Plugs.PaginatorTest do
  use CurrencyConverterWeb.ConnCase, async: true
  use Plug.Test

  import CurrencyConverter.Factory

  alias CurrencyConverterWeb.Plugs.Paginator
  alias Plug.Conn

  setup_all do
    base_params =
      :pagination
      |> string_params_for(order_direction: "ASC")
      |> Map.put("user_id", "1")

    {:ok, base_params: base_params}
  end

  describe "init/1" do
    test "should return the given params" do
      params = %{"A" => "A"}

      response = Paginator.init(params)

      assert response == params
    end
  end

  describe "call/2" do
    test """
           when the given params are valid, returns the treated params
         """,
         %{conn: base_conn, base_params: base_params} do
      conn = %Conn{base_conn | params: base_params}

      response = Paginator.call(conn, %{})

      expected_params = %{
        "limit" => 25,
        "offset" => 0,
        "order_direction" => :asc,
        "page" => 1,
        "user_id" => "1"
      }

      assert %Conn{
               params: ^expected_params,
               halted: false
             } = response
    end

    test """
           when the optional values are not present, returns in the
           treated params with the default values
         """,
         %{conn: base_conn, base_params: base_params} do
      params =
        base_params
        |> Map.delete("limit")
        |> Map.delete("order_direction")

      conn = %Conn{base_conn | params: params}

      response = Paginator.call(conn, %{})

      expected_params = %{
        "limit" => 25,
        "offset" => 0,
        "order_direction" => :desc,
        "page" => 1,
        "user_id" => "1"
      }

      assert %Conn{
               params: ^expected_params,
               halted: false
             } = response
    end

    test """
           when there is invalid params, returns an
           error response body with status 400
         """,
         %{conn: base_conn, base_params: base_params} do
      params = Map.put(base_params, "page", nil)

      conn = %Conn{base_conn | params: params}

      response = Paginator.call(conn, %{})

      expected_response_body =
        ~S({"errors":{"page":["can't be blank"]},"reason":"invalid params","success":false})

      assert %Conn{
               resp_body: ^expected_response_body,
               status: 400,
               halted: true
             } = response
    end
  end
end
