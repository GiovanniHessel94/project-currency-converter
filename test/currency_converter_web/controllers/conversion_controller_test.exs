defmodule CurrencyConverterWeb.ConversionControllerTest do
  use CurrencyConverterWeb.ConnCase, async: true

  import Mox
  import CurrencyConverter.TestUtils, only: [create_conversions_for_user_id: 1]

  alias CurrencyConverter.ElasticSearchApi.ClientMock, as: ElasticSearchClientMock
  alias CurrencyConverter.ExchangeRatesApi.ClientMock, as: ExchangeRatesClientMock

  alias CurrencyConverter.{Conversion, ExchangeRates}

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

  describe "create/2" do
    test "when all params are valid, creates an conversion", %{conn: conn} do
      stub(ElasticSearchClientMock, :log_request, fn _ -> {:ok, %{sucess: true}} end)

      params = %{
        "user_id" => "175",
        "source_amount" => "10.00",
        "source_currency" => "BRL",
        "destination_currency" => "USD"
      }

      expect(
        ExchangeRatesClientMock,
        :fetch_exchange_rates,
        1,
        fn %Conversion{
             source_currency: source_currency,
             destination_currency: destination_currency
           } ->
          assert source_currency == "BRL"
          assert destination_currency == "USD"

          @fetch_exchange_rates_response
        end
      )

      response =
        conn
        |> post(Routes.conversion_path(conn, :create), params)
        |> json_response(:created)

      assert %{
               "data" => %{
                 "conversion" => %{
                   "destination_amount" => "1.97620",
                   "destination_currency" => "USD",
                   "exchange_rate" => "0.19762",
                   "processed_at" => _processed_at,
                   "source_amount" => "10.00000",
                   "source_currency" => "BRL",
                   "user_id" => "175"
                 }
               },
               "success" => true
             } = response
    end

    test """
           when there are some error from changeset, returns the error with the erros key
         """,
         %{conn: conn} do
      stub(ElasticSearchClientMock, :log_request, fn _ -> {:ok, %{sucess: true}} end)

      params = %{
        "user_id" => "175",
        "source_amount" => "10.00",
        "source_currency" => "CRUZEIRO",
        "destination_currency" => "DOGCOIN"
      }

      response =
        conn
        |> post(Routes.conversion_path(conn, :create), params)
        |> json_response(:bad_request)

      expected_response = %{
        "errors" => %{
          "destination_currency" => ["is invalid"],
          "source_currency" => ["is invalid"]
        },
        "reason" => "invalid params",
        "success" => false
      }

      assert response == expected_response
    end

    test """
           when there are some error not from changeset, returns only success and reason
         """,
         %{conn: conn} do
      stub(ElasticSearchClientMock, :log_request, fn _ -> {:ok, %{sucess: true}} end)

      params = %{
        "user_id" => "175",
        "source_amount" => "10.00.0",
        "source_currency" => "CRUZEIRO",
        "destination_currency" => "DOGCOIN"
      }

      response =
        conn
        |> post(Routes.conversion_path(conn, :create), params)
        |> json_response(:bad_request)

      expected_response = %{
        "reason" => "source_amount is not a valid number string representation",
        "success" => false
      }

      assert response == expected_response
    end
  end

  describe "get/2" do
    test """
           when the given user has conversions within the given page,
           returns the conversions with the used params
         """,
         %{conn: conn} do
      stub(ElasticSearchClientMock, :log_request, fn _ -> {:ok, %{sucess: true}} end)

      user_id = "88"

      params = %{
        "user_id" => user_id,
        "page" => 1,
        "limit" => 5
      }

      [
        %Conversion{
          id: expected_first_conversion_id,
          exchange_rate: first_conversion_exchange_rate,
          source_amount: first_conversion_source_amount
        },
        %Conversion{
          id: expected_last_conversion_id,
          exchange_rate: last_conversion_exchange_rate,
          source_amount: last_conversion_source_amount
        }
      ] = create_conversions_for_user_id(user_id)

      response =
        conn
        |> get(Routes.conversion_path(conn, :index, user_id, params))
        |> json_response(:ok)

      expected_first_conversion_exchange_rate =
        Decimal.to_string(
          first_conversion_exchange_rate,
          :normal
        )

      expected_first_destination_amount =
        first_conversion_exchange_rate
        |> CurrencyConverter.calculate_destination_amount(first_conversion_source_amount)
        |> elem(1)
        |> Decimal.round(5)
        |> Decimal.to_string(:normal)

      expected_last_conversion_exchange_rate =
        Decimal.to_string(
          last_conversion_exchange_rate,
          :normal
        )

      expected_last_destination_amount =
        last_conversion_exchange_rate
        |> CurrencyConverter.calculate_destination_amount(last_conversion_source_amount)
        |> elem(1)
        |> Decimal.round(5)
        |> Decimal.to_string(:normal)

      assert %{
               "success" => true,
               "metadata" => %{"limit" => 5, "order_direction" => "desc", "page" => 1},
               "data" => %{
                 "conversions" => [
                   %{
                     "destination_amount" => ^expected_last_destination_amount,
                     "destination_currency" => "USD",
                     "exchange_rate" => ^expected_last_conversion_exchange_rate,
                     "processed_at" => _processed_at_4,
                     "source_amount" => "10.00000",
                     "source_currency" => "BRL",
                     "user_id" => "88",
                     "id" => ^expected_last_conversion_id
                   },
                   %{
                     "destination_amount" => _destination_amount_3,
                     "destination_currency" => "USD",
                     "exchange_rate" => _exchange_rate_3,
                     "processed_at" => _processed_at_3,
                     "source_amount" => "10.00000",
                     "source_currency" => "BRL",
                     "user_id" => "88",
                     "id" => _id_3
                   },
                   %{
                     "destination_amount" => _destination_amount_2,
                     "destination_currency" => "USD",
                     "exchange_rate" => _exchange_rate_2,
                     "processed_at" => _processed_at_2,
                     "source_amount" => "10.00000",
                     "source_currency" => "BRL",
                     "user_id" => "88",
                     "id" => _id_2
                   },
                   %{
                     "destination_amount" => ^expected_first_destination_amount,
                     "destination_currency" => "USD",
                     "exchange_rate" => ^expected_first_conversion_exchange_rate,
                     "processed_at" => _processed_at_1,
                     "source_amount" => "10.00000",
                     "source_currency" => "BRL",
                     "user_id" => "88",
                     "id" => ^expected_first_conversion_id
                   }
                 ]
               }
             } = response
    end

    test """
           when the given user has not conversions within the given page,
           returns an empty list with the used params
         """,
         %{conn: conn} do
      stub(ElasticSearchClientMock, :log_request, fn _ -> {:ok, %{sucess: true}} end)

      user_id = "513"

      params = %{
        "user_id" => user_id,
        "page" => 2,
        "limit" => 25,
        "order_direction" => "ASC"
      }

      create_conversions_for_user_id(user_id)

      response =
        conn
        |> get(Routes.conversion_path(conn, :index, user_id, params))
        |> json_response(:ok)

      expected_response = %{
        "success" => true,
        "metadata" => %{"limit" => 25, "order_direction" => "asc", "page" => 2},
        "data" => %{"conversions" => []}
      }

      assert response == expected_response
    end

    test "when there are some error, returns the error", %{conn: conn} do
      stub(ElasticSearchClientMock, :log_request, fn _ -> {:ok, %{sucess: true}} end)

      user_id = "9999"

      params = %{
        "user_id" => user_id,
        "page" => 0,
        "limit" => 0,
        "order_direction" => "DESC1"
      }

      response =
        conn
        |> get(Routes.conversion_path(conn, :index, user_id, params))
        |> json_response(:bad_request)

      expected_response = %{
        "success" => false,
        "errors" => %{
          "limit" => ["must be greater than or equal to 1"],
          "order_direction" => ["is invalid"],
          "page" => ["must be greater than or equal to 1"]
        },
        "reason" => "invalid params"
      }

      assert response == expected_response
    end
  end
end
