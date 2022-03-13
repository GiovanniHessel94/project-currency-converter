defmodule CurrencyConverterWeb.ConversionController do
  use CurrencyConverterWeb, :controller

  alias CurrencyConverter.Constants.Requests.Events
  alias CurrencyConverter.Conversion

  @convert_currency_event [event: Events.get_convert_currency_event()]
  @fetch_conversions_by_user_event [event: Events.get_fetch_conversions_by_user_event()]

  plug CurrencyConverterWeb.Plugs.RequestLogger, @convert_currency_event when action == :create

  plug CurrencyConverterWeb.Plugs.RequestLogger,
       @fetch_conversions_by_user_event when action == :index

  plug CurrencyConverterWeb.Plugs.Paginator when action == :index

  action_fallback CurrencyConverterWeb.FallbackController

  def create(conn, params) do
    with {:ok, %Conversion{} = conversion} <- CurrencyConverter.create_conversion(params) do
      conn
      |> put_status(:created)
      |> render("show.json", conversion: conversion)
    end
  end

  def index(conn, %{"user_id" => _user_id} = params) do
    with {:ok, conversions} <- CurrencyConverter.get_conversion_by_user_id(params) do
      conn
      |> put_status(:ok)
      |> render("index.json", conversions: conversions, params: params)
    end
  end
end
