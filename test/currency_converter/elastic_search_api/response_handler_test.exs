defmodule CurrencyConverter.ElasticSearchApi.ResponseHandlerTest do
  use ExUnit.Case, async: true

  alias CurrencyConverter.ElasticSearchApi.ResponseHandler
  alias CurrencyConverter.Error

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
          result: "an error occurred while communicating with the elastic search api"
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
            "status" => 400,
            "error" => %{
              "reason" => "failed to parse"
            }
          }
        }
      }

      expected_response = {
        :error,
        %Error{
          status: 400,
          result: "failed to parse"
        }
      }

      response = ResponseHandler.call(params)

      assert response == expected_response
    end

    test """
      when {:error, result} is given as params and the result is
      an Error struct, returns the params
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
      when {:error, result} is given as params and the result is
      an HTTPoison.Error struct, returns an Error struct with
      it's reason as result
    """ do
      params = {
        :error,
        %HTTPoison.Error{reason: :econnrefused}
      }

      expected_response = {
        :error,
        %Error{
          status: :service_unavailable,
          result: ":econnrefused"
        }
      }

      response = ResponseHandler.call(params)

      assert response == expected_response
    end
  end
end
