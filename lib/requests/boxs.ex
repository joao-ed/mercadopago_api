defmodule Mercadopago.Requests.Boxs do
  @moduledoc """
  Documentation for Mercadopago.Requests.Boxs (Point of Sale)

  All functions accept an optional `access_token` parameter as the last argument.
  When provided, the request will be made on behalf of the user who owns that token
  (OAuth authorization_code flow). When omitted, the app's own token is used.
  """

  @doc """
  Search in boxes
  [docs](https://www.mercadopago.com.br/developers/pt/reference/pos/_pos/get)

  ## Parameters

    - `access_token` - Optional. OAuth token to make request on behalf of another user.

  ## Examples

      iex> Mercadopago.Requests.Boxs.search()
      {:ok,%{
      paging: %{limit: 30, offset: 0, total: 1},
      results: [...]}
      }
  """
  def search(access_token \\ nil) do
    Mercadopago.API.get("/pos", access_token)
  end

  @doc """
  Get box
  [docs](https://www.mercadopago.com.br/developers/pt/reference/pos/_pos_id/get)

  ## Parameters

    - `box_id` - The box/POS ID to retrieve
    - `access_token` - Optional. OAuth token to make request on behalf of another user.

  ## Examples

      iex> Mercadopago.Requests.Boxs.show("1212121")
      {:ok,%{
      date_created: "2020-07-07T15:21:20.000-04:00",
      date_last_updated: "2020-09-30T08:09:11.000-04:00",
      external_id: "default",
      fixed_amount: false,
      ...
      }
  """
  def show(box_id, access_token \\ nil) do
    Mercadopago.API.get("/pos/#{box_id}", access_token)
  end

  @doc """
  Create Box
  [docs](https://www.mercadopago.com.br/developers/pt/reference/pos/_pos/post)

  ## Parameters

    - `data` - Box/POS data map
    - `access_token` - Optional. OAuth token to make request on behalf of another user.

  ## Examples

      data = %{
        "name": "First POS",
        "fixed_amount": false,
        "store_id": 1234567,
        "external_store_id": "SUC001",
        "external_id": "SUC001POS001",
        "category": 621102
      }
      Mercadopago.Requests.Boxs.create(data)

  """
  def create(data, access_token \\ nil) do
    Mercadopago.API.post("/pos", data, access_token)
  end

  @doc """
  Update Box
  [docs](https://www.mercadopago.com.br/developers/pt/reference/pos/_pos_id/put)

  ## Parameters

    - `box_id` - The box/POS ID to update
    - `data` - Update data map
    - `access_token` - Optional. OAuth token to make request on behalf of another user.

  ## Examples

      data = %{
        "name": "First POS",
        "fixed_amount": false,
        "category": 621102,
        "store_id": 1234567
      }
      Mercadopago.Requests.Boxs.update("123", data)

  """
  def update(box_id, data, access_token \\ nil) do
    Mercadopago.API.post("/pos/#{box_id}", data, access_token)
  end

  @doc """
  Delete Box
  [docs](https://www.mercadopago.com.br/developers/pt/reference/pos/_pos_id/delete)

  ## Parameters

    - `box_id` - The box/POS ID to delete
    - `access_token` - Optional. OAuth token to make request on behalf of another user.

  ## Examples

      Mercadopago.Requests.Boxs.delete("1")

  """
  def delete(box_id, access_token \\ nil) do
    Mercadopago.API.delete("/pos/#{box_id}", access_token)
  end
end
