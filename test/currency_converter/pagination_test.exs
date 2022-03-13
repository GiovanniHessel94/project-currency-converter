defmodule CurrencyConverter.PaginationTest do
  use CurrencyConverter.DataCase, async: true

  import CurrencyConverter.Factory

  alias CurrencyConverter.Pagination
  alias Ecto.Changeset

  setup_all do
    base_params = params_for(:pagination)

    {:ok, base_params: base_params}
  end

  describe "changeset/2" do
    test """
           when all params are valid and user_id is an
           integer string, returns a valid changeset
         """,
         %{base_params: base_params} do
      params = Map.put(base_params, :page, 25)

      response = Pagination.changeset(params)

      assert %Changeset{changes: %{page: 25}, valid?: true} = response
    end

    test """
           when the required fields are not present, returns an invalid changeset
         """,
         %{base_params: base_params} do
      params =
        base_params
        |> Map.put(:page, nil)
        |> Map.put(:limit, nil)
        |> Map.put(:order_direction, nil)

      response = Pagination.changeset(params)

      assert %Changeset{
               errors: [
                 page: {"can't be blank", [validation: :required]},
                 limit: {"can't be blank", [validation: :required]},
                 order_direction: {"can't be blank", [validation: :required]}
               ],
               valid?: false
             } = response
    end

    test """
           when parsing the struct as the first argument,
           populate the defaults values and returns a
           valid changeset
         """,
         %{base_params: base_params} do
      params =
        base_params
        |> Map.delete(:limit)
        |> Map.delete(:order_direction)

      response = Pagination.changeset(%Pagination{}, params)

      assert %Changeset{
               data: %{limit: 25, order_direction: :desc},
               valid?: true
             } = response
    end

    test """
           when the page is less than 0, returns an invalid changeset
         """,
         %{base_params: base_params} do
      params = Map.put(base_params, :page, -1)

      response = Pagination.changeset(params)

      assert %Changeset{
               errors: [
                 page: {
                   "must be greater than or equal to %{number}",
                   [validation: :number, kind: :greater_than_or_equal_to, number: 1]
                 }
               ],
               valid?: false
             } = response
    end

    test """
           when the limit is less than 0, returns an invalid changeset
         """,
         %{base_params: base_params} do
      params = Map.put(base_params, :limit, -1)

      response = Pagination.changeset(params)

      assert %Changeset{
               errors: [
                 limit: {
                   "must be greater than or equal to %{number}",
                   [validation: :number, kind: :greater_than_or_equal_to, number: 1]
                 }
               ],
               valid?: false
             } = response
    end

    test """
           when the limit is greater than 500, returns an invalid changeset
         """,
         %{base_params: base_params} do
      params = Map.put(base_params, :limit, 501)

      response = Pagination.changeset(params)

      assert %Changeset{
               errors: [
                 limit: {
                   "must be less than or equal to %{number}",
                   [validation: :number, kind: :less_than_or_equal_to, number: 500]
                 }
               ],
               valid?: false
             } = response
    end
  end

  describe "extract_data/1" do
    test "when changeset is valid, extract the pagination data", %{base_params: base_params} do
      params = Map.put(base_params, :page, 25)

      response =
        params
        |> Pagination.changeset()
        |> Pagination.extract_data()

      expected_response = %{
        "limit" => 25,
        "offset" => 600,
        "order_direction" => :desc,
        "page" => 25
      }

      assert response == expected_response
    end
  end
end
