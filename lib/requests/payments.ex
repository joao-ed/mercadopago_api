defmodule Mercadopago.Requests.Payments do
  @moduledoc """
  Documentation for Mercadopago.Requests.Payments

  All functions accept an optional `access_token` parameter as the last argument.
  When provided, the request will be made on behalf of the user who owns that token
  (OAuth authorization_code flow). When omitted, the app's own token is used
  (client_credentials flow).

  ## Example: Creating a payment on behalf of a musician (marketplace/split payment)

      # Using musician's OAuth token to create a payment with application_fee
      payment_data = %{
        transaction_amount: 100.0,
        description: "Tip for song: Wonderwall",
        payment_method_id: "pix",
        payer: %{email: "fan@example.com"},
        application_fee: 10.0  # Your platform's commission
      }

      {:ok, payment} = Mercadopago.Requests.Payments.create(payment_data, musician_access_token)

  """

  @doc """
  Get payment methods
  [docs](https://www.mercadopago.com.br/developers/pt/reference/payment_methods/_payment_methods/get)

  ## Parameters

    - `access_token` - Optional. OAuth token to make request on behalf of another user.

  ## Examples

      iex> Mercadopago.Requests.Payments.methods()
      {:ok, [%{
      deferred_capture: "supported",
      financial_institutions: [],
      id: "amex",
      max_allowed_amount: 60000,
      min_allowed_amount: 0.5,
      name: "American Express",
      payment_type_id: "credit_card",
      processing_modes: ["aggregator"],
      secure_thumbnail: "https://www.mercadopago.com/org-img/MP3/API/logos/amex.gif",
      ...
      }]}
  """
  def methods(access_token \\ nil) do
    Mercadopago.API.get("/v1/payment_methods", access_token)
  end

  @doc """
  Search in payments
  [docs](https://www.mercadopago.com.br/developers/pt/reference/payments/_payments_search/get)

  ## Parameters

    - `access_token` - Optional. OAuth token to make request on behalf of another user.

  ## Examples

      iex> Mercadopago.Requests.Payments.search()
      {:ok, [%{
      date_created: "2023-02-10T19:45:48.000-04:00",
      sponsor_id: nil,
      money_release_status: "released",
      status: "approved",
      date_last_updated: "2023-02-10T19:47:23.000-04:00",
      merchant_number: nil,
      acquirer_reconciliation: [],
      brand_id: nil,
      captured: true,
      order: %{},
      authorization_code: nil,
      date_of_expiration: nil,
      ...
      }]}
  """
  def search(access_token \\ nil) do
    Mercadopago.API.get("/v1/payments/search", access_token)
  end

  @doc """
  Get payment by ID
  [docs](https://www.mercadopago.com.br/developers/pt/reference/payments/_payments_id/get)

  ## Parameters

    - `payment_id` - The payment ID to retrieve
    - `access_token` - Optional. OAuth token to make request on behalf of another user.

  ## Examples

      iex> Mercadopago.Requests.Payments.show("123456789")
      {:ok, %{
      date_created: "2023-02-10T19:45:48.000-04:00",
      sponsor_id: nil,
      money_release_status: "released",
      status: "approved",
      date_last_updated: "2023-02-10T19:47:23.000-04:00",
      merchant_number: nil,
      acquirer_reconciliation: [],
      brand_id: nil,
      captured: true,
      order: %{},
      authorization_code: nil,
      date_of_expiration: nil,
      ...
      }}
  """
  def show(payment_id, access_token \\ nil) do
    Mercadopago.API.get("/v1/payments/#{payment_id}", access_token)
  end

  @doc """
  Create payment
  [docs](https://www.mercadopago.com.br/developers/pt/reference/payments/_payments/post)

  ## Parameters

    - `data` - Payment data map
    - `access_token` - Optional. OAuth token to make request on behalf of another user.
                       **Required for marketplace/split payments.**

  ## Split Payment Example (Marketplace)

  When creating payments on behalf of a seller (musician), use their OAuth token
  and include `application_fee` to specify your platform's commission:

      payment_data = %{
        transaction_amount: 100.0,
        description: "Tip for song: Wonderwall",
        payment_method_id: "pix",
        payer: %{
          email: "fan@example.com"
        },
        application_fee: 10.0  # 10% goes to your platform
      }

      # musician_token obtained via OAuth authorization_code flow
      {:ok, payment} = Mercadopago.Requests.Payments.create(payment_data, musician_token)

  ## Regular Payment Example

      data = %{
        "additional_info": %{
          "items": [
            %{
              "id": "MLB2907679857",
              "title": "Point Mini",
              "description": "Producto Point para cobros con tarjetas mediante bluetooth",
              "picture_url": "https://http2.mlstatic.com/resources/frontend/statics/growth-sellers-landings/device-mlb-point-i_medium@2x.png",
              "category_id": "electronics",
              "quantity": 1,
              "unit_price": 58.8
            }
          ],
          "payer": %{
            "first_name": "Test",
            "last_name": "Test",
            "phone": %{
              "area_code": 11,
              "number": "987654321"
            },
            "address": %{}
          },
          "shipments": %{
            "receiver_address": %{
              "zip_code": "12312-123",
              "state_name": "Rio de Janeiro",
              "city_name": "Buzios",
              "street_name": "Av das Nacoes Unidas",
              "street_number": 3003
            }
          },
          "barcode": %{}
        },
        "description": "Payment for product",
        "external_reference": "MP0001",
        "installments": 1,
        "metadata": %{},
        "payer": %{
          "entity_type": "individual",
          "type": "customer",
          "identification": %{}
        },
        "payment_method_id": "visa",
        "transaction_amount": 58.8
      }
      Mercadopago.Requests.Payments.create(data)

  """
  def create(data, access_token \\ nil) do
    Mercadopago.API.post("/v1/payments", data, access_token)
  end

  @doc """
  Update payment
  [docs](https://www.mercadopago.com.br/developers/pt/reference/payments/_payments_id/put)

  ## Parameters

    - `payment_id` - The payment ID to update
    - `data` - Update data map
    - `access_token` - Optional. OAuth token to make request on behalf of another user.

  ## Examples

      data = %{
        "capture": true,
        "metadata": {},
        "status": "cancelled",
        "transaction_amount": 58.8
      }
      Mercadopago.Requests.Payments.update("12345", data)

  """
  def update(payment_id, data, access_token \\ nil) do
    Mercadopago.API.put("/v1/payments/#{payment_id}", data, access_token)
  end
end
