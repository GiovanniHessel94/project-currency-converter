defmodule CurrencyConverter.ExchangeRatesApi.ResponseHandlerTest do
  use ExUnit.Case, async: true

  alias CurrencyConverter.Error
  alias CurrencyConverter.ExchangeRatesApi.ResponseHandler

  describe "call/1" do
    test """
      when {:ok, response} is given as params and the response status_code
      is between 200 and 299, returns the params
    """ do
      params = {
        :ok,
        %HTTPoison.Response{
          status_code: 200,
          body: %{
            success: true
          }
        }
      }

      response = ResponseHandler.call(params)

      assert response == params
    end

    test """
      when {:ok, response} is given as params but the response status_code
      is not between 200 and 299, when the erros in body are not in the
      expected format returns an error with a generic reason
    """ do
      params = {
        :ok,
        %HTTPoison.Response{
          status_code: 400,
          body: %{
            "success" => false,
            "message" => "an error occurred but is not in the expected format"
          }
        }
      }

      expected_response = {
        :error,
        %Error{
          status: :unprocessable_entity,
          result: "an error occurred while communicating with the exchange rates api"
        }
      }

      response = ResponseHandler.call(params)

      assert response == expected_response
    end

    test """
      when {:ok, response} is given as params but the response status_code
      is not between 200 and 299, when the erros in body are not in the
      expected format returns an error with the reason
    """ do
      params = {
        :ok,
        %HTTPoison.Response{
          status_code: 400,
          body: %{
            "error" => %{
              "code" => "invalid_base_currency",
              "message" =>
                "An unexpected error ocurred. [Technical Support: support@apilayer.com]"
            }
          }
        }
      }

      expected_response = {
        :error,
        %Error{
          status: :unprocessable_entity,
          result:
            "an error occurred while communicating with the exchange rates api." <>
              " an unexpected error ocurred. [technical support: support@apilayer.com]"
        }
      }

      response = ResponseHandler.call(params)

      assert response == expected_response
    end

    test """
      when {:error, result} is given as params and the result is
      an Error struct, returns the param
    """ do
      params = {
        :error,
        %Error{
          status: :service_unavailable,
          result: "Service Unavailable"
        }
      }

      response = ResponseHandler.call(params)

      assert response == params
    end

    test """
      when {:error, result} is given as params and the result is a
      HTTPoison.Error struct, returns service_unavailable an error
    """ do
      params = {
        :error,
        %HTTPoison.Error{}
      }

      expected_response = {
        :error,
        %Error{
          status: :service_unavailable,
          result: "service unavailable"
        }
      }

      response = ResponseHandler.call(params)

      assert response == expected_response
    end
  end
end
