defmodule Mercadopago.Requests.Identification do
  @moduledoc """
  Documentation for Mercadopago.Requests.Identification

  All functions accept an optional `access_token` parameter as the last argument.
  When provided, the request will be made on behalf of the user who owns that token
  (OAuth authorization_code flow). When omitted, the app's own token is used.
  """

  @doc """
  Get document types
  [docs](https://www.mercadopago.com.br/developers/pt/reference/identification_types/_identification_types/get)

  ## Parameters

    - `access_token` - Optional. OAuth token to make request on behalf of another user.

  ## Examples

      iex> Mercadopago.Requests.Identification.search()
      {:ok,[
        %{id: "CPF", max_length: 11, min_length: 11, name: "CPF", type: "number"},
        %{id: "CNPJ", max_length: 14, min_length: 14, name: "CNPJ", type: "number"}
      ]}
  """
  def search(access_token \\ nil) do
    Mercadopago.API.get("/v1/identification_types", access_token)
  end
end
