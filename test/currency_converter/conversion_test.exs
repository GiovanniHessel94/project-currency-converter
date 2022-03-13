defmodule CurrencyConverter.ConversionTest do
  use CurrencyConverter.DataCase, async: true

  import CurrencyConverter.Factory

  alias CurrencyConverter.Conversion
  alias Ecto.Changeset

  setup_all do
    base_params = params_for(:conversion)

    {:ok, base_params: base_params}
  end

  describe "build/1" do
    test """
           when the given changeset is valid, returns the conversion
         """,
         %{base_params: base_params} do
      response =
        base_params
        |> Conversion.changeset()
        |> Conversion.build()

      assert {:ok, %Conversion{}} = response
    end

    test """
           when the given changeset is invalid, returns an error
         """,
         %{base_params: base_params} do
      response =
        base_params
        |> Map.put(:source_currency, "banana")
        |> Conversion.changeset()
        |> Conversion.build()

      assert {:error, %Changeset{action: :create, valid?: false}} = response
    end
  end

  describe "changeset/2" do
    test """
           when all params are valid and user_id is an
           integer string, returns a valid changeset
         """,
         %{base_params: base_params} do
      params = Map.put(base_params, :user_id, "99999")

      response = Conversion.changeset(params)

      assert %Changeset{changes: %{user_id: "99999"}, valid?: true} = response
    end

    test """
           when all params are valid and user_id is
           an uuid, returns a valid changeset
         """,
         %{base_params: base_params} do
      expected_user_id = Ecto.UUID.generate()

      params = Map.put(base_params, :user_id, expected_user_id)

      response = Conversion.changeset(params)

      assert %Changeset{changes: %{user_id: ^expected_user_id}, valid?: true} = response
    end

    test """
           when the required fields are not present, returns an invalid changeset
         """,
         %{base_params: base_params} do
      params =
        base_params
        |> Map.put(:user_id, nil)
        |> Map.put(:source_currency, nil)
        |> Map.put(:source_amount, nil)
        |> Map.put(:destination_currency, nil)

      response = Conversion.changeset(params)

      assert %Changeset{
               errors: [
                 user_id: _another_validation_error,
                 user_id: {"can't be blank", [validation: :required]},
                 source_currency: {"can't be blank", [validation: :required]},
                 source_amount: {"can't be blank", [validation: :required]},
                 destination_currency: {"can't be blank", [validation: :required]}
               ],
               valid?: false
             } = response
    end

    test """
           when user_id isn't an integer string uuid,
           returns an invalid changeset
         """,
         %{base_params: base_params} do
      params = Map.put(base_params, :user_id, "banana")

      response = Conversion.changeset(params)

      assert %Changeset{
               errors: [
                 user_id: {
                   "user id must be a positive integer or an UUID",
                   [validation: :invalid_user_id_format]
                 }
               ],
               valid?: false
             } = response
    end

    test """
           when the source_currency aren't in the available currencies,
           returns an invalid changeset
         """,
         %{base_params: base_params} do
      params = Map.put(base_params, :source_currency, "CRUZEIRO")

      response = Conversion.changeset(params)

      assert %Changeset{
               errors: [
                 source_currency: {
                   "is invalid",
                   [
                     validation: :inclusion,
                     enum: _enum
                   ]
                 }
               ],
               valid?: false
             } = response
    end

    test """
           when the source_amount is less than 0, returns an invalid changeset
         """,
         %{base_params: base_params} do
      params = Map.put(base_params, :source_amount, Decimal.new("-1"))

      response = Conversion.changeset(params)

      assert %Changeset{
               errors: [
                 source_amount: {
                   "must be greater than or equal to %{number}",
                   [validation: :number, kind: :greater_than_or_equal_to, number: 0]
                 }
               ],
               valid?: false
             } = response
    end

    test """
           when the destination_currency aren't in the available currencies,
           returns an invalid changeset
         """,
         %{base_params: base_params} do
      params = Map.put(base_params, :destination_currency, "CRUZEIRO")

      response = Conversion.changeset(params)

      assert %Changeset{
               errors: [
                 destination_currency: {
                   "is invalid",
                   [
                     validation: :inclusion,
                     enum: _enum
                   ]
                 }
               ],
               valid?: false
             } = response
    end

    test """
           when the destination_amount is less than 0, returns an invalid changeset
         """,
         %{base_params: base_params} do
      params = Map.put(base_params, :destination_amount, Decimal.new("-1"))

      response = Conversion.changeset(params)

      assert %Changeset{
               errors: [
                 destination_amount: {
                   "must be greater than or equal to %{number}",
                   [validation: :number, kind: :greater_than_or_equal_to, number: 0]
                 }
               ],
               valid?: false
             } = response
    end

    test """
           when the exchange_rate is less than 0, returns an invalid changeset
         """,
         %{base_params: base_params} do
      params = Map.put(base_params, :exchange_rate, Decimal.new("-1"))

      response = Conversion.changeset(params)

      assert %Changeset{
               errors: [
                 exchange_rate: {
                   "must be greater than or equal to %{number}",
                   [validation: :number, kind: :greater_than_or_equal_to, number: 0]
                 }
               ],
               valid?: false
             } = response
    end

    test """
           when the currencies are the same, returns an invalid changeset
         """,
         %{base_params: base_params} do
      params =
        base_params
        |> Map.put(:source_currency, "JPY")
        |> Map.put(:destination_currency, "JPY")

      response = Conversion.changeset(params)

      assert %Changeset{
               errors: [
                 destination_currency: {
                   "source and destination currencies can not be the same",
                   [validation: :invalid_currencies]
                 },
                 source_currency: {
                   "source and destination currencies can not be the same",
                   [validation: :invalid_currencies]
                 }
               ],
               valid?: false
             } = response
    end
  end
end
