defmodule CurrencyConverter.Conversions.CreateTest do
  use CurrencyConverter.DataCase, async: true

  import CurrencyConverter.Factory
  import Mox

  alias CurrencyConverter.{
    Conversion,
    Conversions.Create,
    Error,
    ExchangeRates,
    ExternalServices.ExchangeRatesApi.ClientMock
  }

  alias Ecto.Changeset

  @fetch_exchange_rates_response {
    :ok,
    %ExchangeRates{
      base: "EUR",
      exchange_rates: %{
        "BRL" => 5.516996,
        "JPY" => 126.131524,
        "USD" => 1.090251
      },
      timestamp: 1_646_780_822
    }
  }

  setup_all do
    base_params =
      string_params_for(
        :conversion,
        source_amount: "10.10",
        source_currency: "USD",
        destination_currency: "BRL"
      )

    {:ok, base_params: base_params}
  end

  describe "call/1" do
    setup :verify_on_exit!

    test """
           when the given params are valid, returns
           the created conversion
         """,
         %{base_params: %{"user_id" => user_id} = base_params} do
      expect(
        ClientMock,
        :fetch_exchange_rates,
        1,
        fn %Conversion{
             source_currency: source_currency,
             destination_currency: destination_currency
           } ->
          assert source_currency == "USD"
          assert destination_currency == "BRL"

          @fetch_exchange_rates_response
        end
      )

      response = Create.call(base_params)

      expected_destination_amount = Decimal.new("51.10901")
      expected_exchange_rate = Decimal.new("5.0602980967667966062829626232515478101")
      expected_source_amount = Decimal.new("10.10000")

      assert {
               :ok,
               %Conversion{
                 created_at: _created_at,
                 destination_amount: ^expected_destination_amount,
                 destination_currency: "BRL",
                 exchange_rate: ^expected_exchange_rate,
                 id: _id,
                 processed_at: _processed_at,
                 source_amount: ^expected_source_amount,
                 source_currency: "USD",
                 updated_at: _updated_at,
                 user_id: ^user_id
               }
             } = response
    end

    test """
      when the required fields are not present, returns an
      error with an invalid changeset
    """ do
      expect(ClientMock, :fetch_exchange_rates, 0, & &1)

      response = Create.call(%{})

      assert {
               :error,
               %Changeset{
                 errors: [
                   {
                     :user_id,
                     {
                       "user id must be a positive integer or an UUID",
                       [validation: :invalid_user_id_format]
                     }
                   },
                   {:user_id, {"can't be blank", [validation: :required]}},
                   {:source_currency, {"can't be blank", [validation: :required]}},
                   {:source_amount, {"can't be blank", [validation: :required]}},
                   {:destination_currency, {"can't be blank", [validation: :required]}}
                 ],
                 valid?: false
               }
             } = response
    end

    test """
           when there is invalid params, returns an
           error with an invalid changeset
         """,
         %{base_params: base_params} do
      expect(ClientMock, :fetch_exchange_rates, 0, & &1)

      params =
        base_params
        |> Map.put("user_id", "hehehe")
        |> Map.put("source_currency", "CRUZEIRO")
        |> Map.put("destination_currency", "DOGCOIN")

      response = Create.call(params)

      assert {
               :error,
               %Changeset{
                 errors: [
                   destination_currency: {
                     "is invalid",
                     [validation: :inclusion, enum: _enum_1]
                   },
                   source_currency: {
                     "is invalid",
                     [validation: :inclusion, enum: _enum_2]
                   },
                   user_id: {
                     "user id must be a positive integer or an UUID",
                     [validation: :invalid_user_id_format]
                   }
                 ],
                 valid?: false
               }
             } = response
    end

    test """
           when source_amount is not a valid number
           representation, returns an error
         """,
         %{base_params: base_params} do
      expect(ClientMock, :fetch_exchange_rates, 0, & &1)

      params = Map.put(base_params, "source_amount", "10.10.1")

      response = Create.call(params)

      assert {
               :error,
               %Error{
                 result: "source_amount is not a valid number string representation",
                 status: :bad_request
               }
             } = response
    end

    test """
           when source_amount is out of the precision range, returns an error
         """,
         %{base_params: base_params} do
      expect(ClientMock, :fetch_exchange_rates, 0, & &1)

      params = Map.put(base_params, "source_amount", "1000000000000000000000000000000000.925555")

      response = Create.call(params)

      assert {
               :error,
               %Error{
                 result:
                   "source_amount is not within the precision of 38 digits which 5 are for decimal places",
                 status: :bad_request
               }
             } = response
    end
  end
end
