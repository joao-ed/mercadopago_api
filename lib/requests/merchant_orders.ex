defmodule Mercadopago.Requests.MerchantOrders do
  @moduledoc """
  Documentation for Mercadopago.Requests.MerchantOrders

  All functions accept an optional `access_token` parameter as the last argument.
  When provided, the request will be made on behalf of the user who owns that token
  (OAuth authorization_code flow). When omitted, the app's own token is used.
  """

  @doc """
  Search in orders
  [docs](https://www.mercadopago.com.br/developers/pt/reference/merchant_orders/_merchant_orders_search/get)

  ## Parameters

    - `access_token` - Optional. OAuth token to make request on behalf of another user.

  ## Examples

      iex> Mercadopago.Requests.MerchantOrders.search()
      {:ok,%{...,
        [...,
        shipments: [],
        shipping_cost: 0,
        site_id: "MLB",
        sponsor_id: nil,
        status: "closed",
        total_amount: 250.74
      }
      ],
      next_offset: 20,
      total: 114
      }
  """
  def search(access_token \\ nil) do
    Mercadopago.API.get("/merchant_orders/search", access_token)
  end

  @doc """
  Get order
  [docs](https://www.mercadopago.com.br/developers/pt/reference/merchant_orders/_merchant_orders_id/get)

  ## Parameters

    - `order_id` - The order ID to retrieve
    - `access_token` - Optional. OAuth token to make request on behalf of another user.

  ## Examples

      iex> Mercadopago.Requests.MerchantOrders.show("121221")
      {:ok,%{
      additional_info: "",
      application_id: nil,
      cancelled: false,
      collector: %{},
      ...
      }
  """
  def show(order_id, access_token \\ nil) do
    Mercadopago.API.get("/merchant_orders/#{order_id}", access_token)
  end

  @doc """
  Create order
  [docs](https://www.mercadopago.com.br/developers/pt/reference/merchant_orders/_merchant_orders/post)

  ## Parameters

    - `data` - Order data map
    - `access_token` - Optional. OAuth token to make request on behalf of another user.

  ## Examples

      data = %{
        "external_reference": "default",
        "preference_id": "Preference identification",
        "payer": {
          "id": 123,
          "nickname": "JOHN"
        },
        "site_id": "MLA",
        "items": [
          {
            "id": "item id",
            "category_id": "item category",
            "currency_id": "BRL",
            "description": "item description",
            "picture_url": "item picture",
            "quantity": 1,
            "unit_price": 5,
            "title": "item title"
          }
        ],
        "application_id": 10000000000000000
      }
      Mercadopago.Requests.MerchantOrders.create(data)

  """
  def create(data, access_token \\ nil) do
    Mercadopago.API.post("/merchant_orders", data, access_token)
  end

  @doc """
  Update order
  [docs](https://www.mercadopago.com.br/developers/pt/reference/merchant_orders/_merchant_orders_id/put)

  ## Parameters

    - `order_id` - The order ID to update
    - `data` - Update data map
    - `access_token` - Optional. OAuth token to make request on behalf of another user.

  ## Examples

      data = %{
        "external_reference": "default",
        "preference_id": "Preference identification",
        "payer": {
          "id": 123,
          "nickname": "JOHN"
        },
        "site_id": "MLA",
        "items": [
          {
            "id": "item id",
            "category_id": "item category",
            "currency_id": "BRL",
            "description": "item description",
            "picture_url": "item picture",
            "quantity": 1,
            "unit_price": 5,
            "title": "item title"
          }
        ],
        "application_id": 10000000000000000
      }
      Mercadopago.Requests.MerchantOrders.update("12345", data)

  """
  def update(order_id, data, access_token \\ nil) do
    Mercadopago.API.put("/merchant_orders/#{order_id}", data, access_token)
  end
end
