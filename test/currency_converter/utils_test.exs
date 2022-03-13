defmodule CurrencyConverter.UtilsTest do
  use ExUnit.Case, async: true

  alias CurrencyConverter.Utils

  describe "format_microseconds/1" do
    test """
      when microseconds are equal or greater than
      1000, format it as a milliseconds string
    """ do
      microseconds = 1000

      response = Utils.format_microseconds(microseconds)

      expected_response = "1ms"

      assert response == expected_response
    end

    test "when microseconds are less than 1000, format it as a microseconds string" do
      microseconds = 999

      response = Utils.format_microseconds(microseconds)

      expected_response = "999µs"

      assert response == expected_response
    end
  end

  describe "remove_keys_from_map/2" do
    test """
      when the keys are present in the map and
      are in the same format, remove the keys
    """ do
      string_map = %{
        "a" => "a",
        "b" => "b"
      }

      keys = ["a"]

      response = Utils.remove_keys_from_map(string_map, keys)

      expected_response = %{"b" => "b"}

      assert response == expected_response
    end

    test """
      when the keys are present in the map but aren't
      in the same format, don't remove the keys
    """ do
      atom_map = %{
        a: "a",
        b: "b"
      }

      keys = ["a", "b"]

      response = Utils.remove_keys_from_map(atom_map, keys)

      expected_response = %{
        a: "a",
        b: "b"
      }

      assert response == expected_response
    end

    test """
      when the keys aren't present in the
      map don't remove the any key
    """ do
      string_map = %{
        "a" => "a",
        "b" => "b"
      }

      keys = ["c", "d"]

      response = Utils.remove_keys_from_map(string_map, keys)

      assert response == string_map
    end
  end

  describe "value_to_string/1" do
    test """
      when value can be transformed in string by using the
      to_string function, returns the string value
    """ do
      value = 1000

      response = Utils.value_to_string(value)

      expected_response = to_string(value)

      assert response == expected_response
    end

    test """
      when value can't be transformed in string by using the
      to_string function raising the 'Protocol.UndefinedError'
      exception, returns the inspected value
    """ do
      value = {:banana, true}

      response = Utils.value_to_string(value)

      assert_raise Protocol.UndefinedError, fn ->
        to_string(value)
      end

      expected_response = inspect(value)

      assert response == expected_response
    end
  end

  describe "get_env/2" do
    test """
      when the given env exist in the system, returns its value
    """ do
      env = "ELASTIC_SEARCH_API_ENABLED_1"

      System.put_env("ELASTIC_SEARCH_API_ENABLED_1", "true")

      response = Utils.get_env(env)

      expected_response = "true"

      assert response == expected_response
    end

    test """
      when the given env exist in the app config, returns its value
    """ do
      env = :elastic_search_api_enabled_2

      Application.put_env(:currency_converter, :elastic_search_api_enabled_2, true)

      response = Utils.get_env(env)

      expected_response = true

      assert response == expected_response
    end

    test """
      when the given env don't exists but a default
      value is given, returns the default value
    """ do
      env = "ELASTIC_SEARCH_API_ENABLED_3"

      response = Utils.get_env(env, "banana")

      expected_response = "banana"

      assert response == expected_response
    end

    test """
      when the given env exist in the system, even if the given
      key is an atom, returns its value
    """ do
      env = :elastic_search_api_enabled_4

      System.put_env("ELASTIC_SEARCH_API_ENABLED_4", "true")

      response = Utils.get_env(env)

      expected_response = "true"

      assert response == expected_response
    end

    test """
      when the given env exist in app config, even if the given
      key is an string, returns its value
    """ do
      env = "ELASTIC_SEARCH_API_ENABLED_5"

      Application.put_env(:currency_converter, :elastic_search_api_enabled_5, true)

      response = Utils.get_env(env)

      expected_response = true

      assert response == expected_response
    end
  end
end
