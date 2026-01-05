defmodule Mercadopago.Requests.Preferences do
  @moduledoc """
  Documentation for Mercadopago.Requests.Preferences

  All functions accept an optional `access_token` parameter as the last argument.
  When provided, the request will be made on behalf of the user who owns that token
  (OAuth authorization_code flow). When omitted, the app's own token is used.

  ## Marketplace Usage with Split Payments

  For Checkout Pro with split payments, use `marketplace_fee` instead of `application_fee`:

      preference_data = %{
        items: [%{title: "Tip", quantity: 1, unit_price: 100.0}],
        marketplace_fee: 10.0  # Your platform's commission
      }

      {:ok, preference} = Mercadopago.Requests.Preferences.create(preference_data, seller_token)

  """

  @doc """
  Search in preferences
  [docs](https://www.mercadopago.com.br/developers/pt/reference/preferences/_checkout_preferences_search/get)

  ## Parameters

    - `access_token` - Optional. OAuth token to make request on behalf of another user.

  ## Examples

      iex> Mercadopago.Requests.Preferences.search()
      {:ok,%{
      "elements": [
        %{
          "id": "202809963-a2201f8d-11cb-443f-adf6-de5a42eed67d",
          "client_id": 6295877106812064,
          "collector_id": 202809963,
          "date_created": "2018-02-02T19:18:51.150Z",
          "items": [
            %{}
          ],
          "marketplace": "NONE",
          "site_id": "MLA",
          "sponsor_id": 0
        }
      ],
      "next_offset": 1,
      "total": 1
      }
      }
  """
  def search(access_token \\ nil) do
    Mercadopago.API.get("/checkout/preferences/search", access_token)
  end

  @doc """
  Get preference
  [docs](https://www.mercadopago.com.br/developers/pt/reference/preferences/_checkout_preferences_id/get)

  ## Parameters

    - `preference_id` - The preference ID to retrieve
    - `access_token` - Optional. OAuth token to make request on behalf of another user.

  ## Examples

      iex> Mercadopago.Requests.Preferences.show("1212121")
      {:ok,%{
        "back_urls": %{},
        "client_id": 6295877106812064,
        "collector_id": 202809963,
        "date_created": "2018-02-02T19:18:51.150Z",
        "id": "202809963-a2201f8d-11cb-443f-adf6-de5a42eed67d",
        "init_point": "https://www.mercadopago.com/mla/checkout/start?pref_id=202809963-a2201f8d-11cb-443f-adf6-de5a42eed67d",
        "items": [
          %{
            "id": "item-ID-1234",
            "currency_id": "$",
            "title": "Practical Granite Shirt",
            "picture_url": "http://placehold.it/350x150",
            "description": "This is my description",
            "quantity": 2,
            "unit_price": 14.5
          }
        ],
        "marketplace": "MP-MKT-6295877106812064",
        "marketplace_fee": 0,
        "statement_descriptor": "MERCADOPAGO",
        "payer": %{
          "phone": %{
            "number": "631.586.0213"
          },
          "address": %{
            "zip_code": 76336,
            "street_name": "Marjory Stream",
            "street_number": 941
          },
          "identification": %{
            "number": 12345678,
            "type": "DNI"
          }
        },
        "payment_methods": %{
          "excluded_payment_methods": [
            %{}
          ],
          "excluded_payment_types": [
            %{}
          ]
        },
        "sandbox_init_point": "https://sandbox.mercadopago.com/mla/checkout/pay?pref_id=202809963-a2201f8d-11cb-443f-adf6-de5a42eed67d",
        "shipments": %{
          "receiver_address": {}
        }
      }
  """
  def show(preference_id, access_token \\ nil) do
    Mercadopago.API.get("/checkout/preferences/#{preference_id}", access_token)
  end

  @doc """
  Create preference
  [docs](https://www.mercadopago.com.br/developers/pt/reference/preferences/_checkout_preferences/post)

  ## Parameters

    - `data` - Preference data map
    - `access_token` - Optional. OAuth token to make request on behalf of another user.
                       **Required for marketplace/split payments.**

  ## Examples

      data = %{
        "items": [
          %{
            "title": "Dummy Title",
            "description": "Dummy description",
            "picture_url": "http://www.myapp.com/myimage.jpg",
            "category_id": "services",
            "quantity": 1,
            "currency_id": "BRL",
            "unit_price": 10
          }
        ]
      }
      Mercadopago.Requests.Preferences.create(data)

  """
  def create(data, access_token \\ nil) do
    Mercadopago.API.post("/checkout/preferences", data, access_token)
  end

  @doc """
  Update Preference
  [docs](https://www.mercadopago.com.br/developers/pt/reference/preferences/_checkout_preferences_id/put)

  ## Parameters

    - `preference_id` - The preference ID to update
    - `data` - Update data map
    - `access_token` - Optional. OAuth token to make request on behalf of another user.

  ## Examples

      data = %{
        "items": [
          %{
            "title": "Dummy Title",
            "description": "Dummy description",
            "picture_url": "http://www.myapp.com/myimage.jpg",
            "category_id": "car_electronics",
            "quantity": 1,
            "currency_id": "U$",
            "unit_price": 10
          }
        ],
        "payer": %{
          "phone": %{},
          "identification": %{},
          "address": %{}
        },
        "payment_methods": %{
          "excluded_payment_methods": [
            %{}
          ],
          "excluded_payment_types": [
            %{}
          ]
        },
        "shipments": %{
          "free_methods": [
            %{}
          ],
          "receiver_address": %{}
        },
        "back_urls": %{},
        "differential_pricing": %{},
        "tracks": [
          %{
            "type": "google_ad"
          }
        ],
        "metadata": %{}
      }
      Mercadopago.Requests.Preferences.update("12345", data)

  """
  def update(preference_id, data, access_token \\ nil) do
    Mercadopago.API.post("/checkout/preferences/#{preference_id}", data, access_token)
  end
end
