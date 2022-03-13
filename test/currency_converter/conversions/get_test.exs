defmodule CurrencyConverter.Conversions.GetTest do
  use CurrencyConverter.DataCase, async: true

  import CurrencyConverter.Factory
  import CurrencyConverter.TestUtils, only: [create_conversions_for_user_id: 1]

  alias CurrencyConverter.{
    Conversion,
    Conversions.Get,
    Pagination
  }

  @user_id Ecto.UUID.generate()

  describe "by_user_id/1" do
    test """
      when the given user has conversions within the given page
      and order_direction is :asc returns the conversions list
      with the first conversion as the first element
    """ do
      [
        %Conversion{id: first_conversion_id},
        %Conversion{id: last_conversion_id}
      ] = create_conversions_for_user_id(@user_id)

      params = create_params([limit: 2, order_direction: :asc], @user_id)

      response = Get.by_user_id(params)

      assert {
               :ok,
               [
                 %Conversion{id: ^first_conversion_id},
                 %Conversion{id: second_conversion_id}
               ]
             } = response

      assert second_conversion_id != last_conversion_id
    end

    test """
     when the given user has conversions within the given page
     and order_direction is :desc returns the conversions list
     with the last conversion as the first element
    """ do
      [
        %Conversion{id: first_conversion_id},
        %Conversion{id: last_conversion_id}
      ] = create_conversions_for_user_id(@user_id)

      params = create_params([limit: 2, order_direction: :desc], @user_id)

      response = Get.by_user_id(params)

      assert {
               :ok,
               [
                 %Conversion{id: ^last_conversion_id},
                 %Conversion{id: third_conversion_id}
               ]
             } = response

      assert third_conversion_id != first_conversion_id
    end

    test """
     when the given user has conversions but they are not
     within the given page, returns an empty list
    """ do
      create_conversions_for_user_id(@user_id)

      params = create_params([page: 2, limit: 5], @user_id)

      response = Get.by_user_id(params)

      assert {:ok, []} = response
    end

    test """
     when the given user not conversions, returns an empty list
    """ do
      params = create_params("999")

      response = Get.by_user_id(params)

      assert {:ok, []} = response
    end
  end

  defp create_params(pagination_attrs \\ [page: 1, limit: 2], user_id),
    do:
      :pagination
      |> params_for(pagination_attrs)
      |> Pagination.changeset()
      |> Pagination.extract_data()
      |> Map.put("user_id", user_id)
end
