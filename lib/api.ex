defmodule Mercadopago.API do
  require Logger

  @moduledoc """
  Documentation for Mercadopago.API. This module is about the base HTTP functionality
  """
  @base_url "https://api.mercadopago.com"

  @doc """
  Requests an OAuth token from Mercadopago, returns a tuple containing the token and seconds till expiry.

  Possible returns:

  - {:ok, data}
  - {:error, reason}

  ## Examples

      iex> Mercadopago.API.create_token()
      {:ok, {..}}
  """
  def create_token() do
    params = %{
      "client_id" => Mercadopago.Config.get().client_id,
      "client_secret" => Mercadopago.Config.get().client_secret,
      "grant_type" => "client_credentials"
    }

    headers = [
      {"content-type", "application/x-www-form-urlencoded"}
    ]

    case HTTPoison.post(base_url() <> "/oauth/token", Poison.encode!(params), headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        token = body |> Poison.decode!()

        Logger.info("Access token obtained successfully.")
        {:ok, {token["access_token"], token["expires_in"]}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Error getting access token: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Make an HTTP GET request to the correct API, adding the authentication required header.

  Possible returns:

  - {:ok, data}
  - {:ok, :not_found}
  - {:ok, :no_content}
  - {:error, :bad_network}
  - {:error, reason}

  ## Parameters

    - `url` - The API endpoint path (e.g., "/v1/payments/123")
    - `access_token` - Optional. If provided, uses this token instead of the app's token.
                       Use this when making requests on behalf of another user (OAuth flow).

  ## Examples

      # Using app's token (client_credentials)
      iex> Mercadopago.API.get("/v1/payments/123")
      {:ok, {...}}

      # Using a musician's token (authorization_code flow)
      iex> Mercadopago.API.get("/v1/payments/123", "APP_USR-musician-token")
      {:ok, {...}}

  """
  def get(url, access_token \\ nil) do
    case HTTPoison.get(base_url() <> url, headers(access_token)) do
      {:ok, %{status_code: 404}} ->
        {:error, :not_found}

      {:ok, %{status_code: 401}} ->
        {:error, :unauthorised}

      {:ok, %{status_code: 400}} ->
        {:error, :not_found}

      {:ok, %{status_code: 204}} ->
        {:ok, :no_content}

      {:ok, %{body: body, status_code: 200}} ->
        {:ok, Poison.decode!(body, %{keys: :atoms})}

      {:ok, %{body: body}} ->
        {:error, body}

      _ ->
        {:error, :bad_network}
    end
  end

  @doc """
  Make an HTTP POST request to the correct API, adding the authentication required header.

  ## Parameters

    - `url` - The API endpoint path (e.g., "/v1/payments")
    - `data` - The request body as a map or list
    - `access_token` - Optional. If provided, uses this token instead of the app's token.
                       Use this when making requests on behalf of another user (OAuth flow).
    - `idempotency_key` - Optional. When provided, sends the "X-Idempotency-Key" header.
                          Use this for safely retrying payment creation requests.

  ## Examples

      # Using app's token (client_credentials)
      iex> Mercadopago.API.post("/v1/payments", %{amount: 100})
      {:ok, {...}}

      # Using a musician's token (authorization_code flow)
      iex> Mercadopago.API.post("/v1/payments", %{amount: 100}, "APP_USR-musician-token")
      {:ok, {...}}

      # With idempotency key
      iex> Mercadopago.API.post("/v1/payments", %{amount: 100}, nil, "your-idempotency-key")
      {:ok, {...}}

  """
  @spec post(String.t(), map | list | nil, String.t() | nil, String.t() | nil) ::
          {:ok, map | :not_found | :no_content | nil}
          | {:error, :unauthorised | :bad_request | :not_found | :bad_network | any}
  def post(url, data, access_token \\ nil, idempotency_key \\ nil) do
    {:ok, data} = Poison.encode(data)

    case HTTPoison.post(base_url() <> url, data, headers(access_token, idempotency_key)) do
      {:ok, %{status_code: 404, body: body}} ->
        Logger.warning("POST #{url} returned 404: #{inspect(body)}")
        {:error, :not_found}

      {:ok, %{status_code: 401, body: body}} ->
        Logger.warning("POST #{url} returned 401: #{inspect(body)}")
        {:error, :unauthorised}

      {:ok, %{status_code: 400, body: body}} ->
        Logger.error("POST #{url} returned 400: #{inspect(body)}")
        {:error, :bad_request}

      {:ok, %{status_code: 204}} ->
        {:ok, nil}

      {:ok, %{body: body, status_code: 201}} ->
        {:ok, Poison.decode!(body, %{keys: :atoms})}

      {:ok, %{body: body, status_code: 200}} ->
        {:ok, Poison.decode!(body, %{keys: :atoms})}

      {:ok, %{status_code: status_code, body: body}} ->
        Logger.error("POST #{url} returned #{status_code}: #{inspect(body)}")
        {:error, body}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("POST #{url} failed: #{inspect(reason)}")
        {:error, :bad_network}

      _error ->
        Logger.error("POST #{url} failed with an unknown error.")
        {:error, :bad_network}
    end
  end

  @doc """
  Make an HTTP PUT request to the correct API, adding the authentication required header.

  ## Parameters

    - `url` - The API endpoint path (e.g., "/v1/payments/123")
    - `data` - The request body as a map or list
    - `access_token` - Optional. If provided, uses this token instead of the app's token.
                       Use this when making requests on behalf of another user (OAuth flow).

  ## Examples

      # Using app's token (client_credentials)
      iex> Mercadopago.API.put("/v1/payments/123", %{status: "cancelled"})
      {:ok, {...}}

      # Using a musician's token (authorization_code flow)
      iex> Mercadopago.API.put("/v1/payments/123", %{status: "cancelled"}, "APP_USR-musician-token")
      {:ok, {...}}

  """
  @spec put(String.t(), map | list | nil, String.t() | nil) ::
          {:ok, map | :not_found | :no_content | nil}
          | {:error, :unauthorised | :bad_network | any}
  def put(url, data, access_token \\ nil) do
    {:ok, data} = Poison.encode(data)

    case HTTPoison.put(base_url() <> url, data, headers(access_token)) do
      {:ok, %{status_code: 404}} ->
        {:error, :not_found}

      {:ok, %{status_code: 401}} ->
        {:error, :unauthorised}

      {:ok, %{status_code: 400}} ->
        {:error, :bad_request}

      {:ok, %{status_code: 204}} ->
        {:ok, nil}

      {:ok, %{body: body, status_code: 201}} ->
        {:ok, Poison.decode!(body, %{keys: :atoms})}

      {:ok, %{body: body, status_code: 200}} ->
        {:ok, Poison.decode!(body, %{keys: :atoms})}

      {:ok, %{body: body}} = resp ->
        IO.inspect(resp)
        {:error, body}

      _ ->
        {:error, :bad_network}
    end
  end

  @doc """
  Make an HTTP DELETE request to the correct API, adding the authentication required header.

  ## Parameters

    - `url` - The API endpoint path (e.g., "/v1/payments/123")
    - `access_token` - Optional. If provided, uses this token instead of the app's token.
                       Use this when making requests on behalf of another user (OAuth flow).

  ## Examples

      # Using app's token (client_credentials)
      iex> Mercadopago.API.delete("/pos/123")
      {:ok, {...}}

      # Using a musician's token (authorization_code flow)
      iex> Mercadopago.API.delete("/pos/123", "APP_USR-musician-token")
      {:ok, {...}}

  """
  def delete(url, access_token \\ nil) do
    case HTTPoison.delete(base_url() <> url, headers(access_token)) do
      {:ok, %{status_code: 404}} ->
        {:error, :not_found}

      {:ok, %{status_code: 401}} ->
        {:error, :unauthorised}

      {:ok, %{status_code: 400}} ->
        {:error, :not_found}

      {:ok, %{status_code: 204}} ->
        {:ok, :no_content}

      {:ok, %{body: body, status_code: 200}} ->
        {:ok, Poison.decode!(body, %{keys: :atoms})}

      {:ok, %{body: body}} ->
        {:error, body}

      _ ->
        {:error, :bad_network}
    end
  end

  defp headers(nil) do
    [
      {"Authorization", "Bearer #{mercadopago_token()}"},
      {"Content-Type", "application/json"}
    ]
  end

  defp headers(access_token) do
    [
      {"Authorization", "Bearer #{access_token}"},
      {"Content-Type", "application/json"}
    ]
  end

  defp headers(access_token, idempotency_key) do
    access_token
    |> headers()
    |> maybe_put_idempotency_key(idempotency_key)
  end

  defp maybe_put_idempotency_key(headers, nil), do: headers

  defp maybe_put_idempotency_key(headers, idempotency_key),
    do: [{"X-Idempotency-Key", idempotency_key} | headers]

  defp base_url,
    do: @base_url

  defp mercadopago_token,
    do: Mercadopago.get_token()
end
