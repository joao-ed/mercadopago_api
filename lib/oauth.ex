defmodule Mercadopago.OAuth do
  @moduledoc """
  OAuth 2.0 Authorization Code flow for Mercado Pago.

  This module handles the OAuth flow needed for marketplace integrations where
  your application needs to act on behalf of other Mercado Pago users (sellers).

  ## Flow Overview

  1. Generate authorization URL and redirect user to Mercado Pago
  2. User authorizes your application
  3. Mercado Pago redirects back with an authorization code
  4. Exchange the code for access_token and refresh_token
  5. Store tokens securely in your database
  6. Use access_token to make API calls on behalf of the user
  7. When access_token expires, use refresh_token to get a new one

  ## Example Usage

      # Step 1: Generate URL and redirect user
      url = Mercadopago.OAuth.authorization_url("https://myapp.com/callback")
      # Redirect user to this URL

      # Step 2-3: User authorizes, MP redirects to your callback with ?code=XXX

      # Step 4: Exchange code for tokens
      {:ok, tokens} = Mercadopago.OAuth.exchange_code("AUTH_CODE", "https://myapp.com/callback")
      # tokens = %{
      #   access_token: "APP_USR-xxx",
      #   refresh_token: "TG-xxx",
      #   expires_in: 21600,
      #   user_id: 123456789,
      #   public_key: "APP_USR-xxx",
      #   token_type: "Bearer",
      #   scope: "read write offline_access"
      # }

      # Step 5: Store in your database (encrypt the tokens!)

      # Step 6: Make API calls on behalf of user
      Mercadopago.Requests.Payments.create(payment_data, tokens.access_token)

      # Step 7: When token expires, refresh it
      {:ok, new_tokens} = Mercadopago.OAuth.refresh_token(stored_refresh_token)

  """

  require Logger

  @auth_url "https://auth.mercadopago.com/authorization"
  @token_url "https://api.mercadopago.com/oauth/token"

  @doc """
  Generates the authorization URL to redirect the user to Mercado Pago.

  The user will be asked to log in and authorize your application.
  After authorization, they will be redirected to your `redirect_uri` with a `code` parameter.

  ## Parameters

    - `redirect_uri` - The URL where Mercado Pago will redirect after authorization.
                       Must match the URL configured in your application settings.
    - `opts` - Optional keyword list:
      - `:state` - A random string to prevent CSRF attacks. Will be returned in the callback.
      - `:response_type` - Default "code". Usually shouldn't be changed.

  ## Examples

      iex> Mercadopago.OAuth.authorization_url("https://myapp.com/callback")
      "https://auth.mercadopago.com/authorization?client_id=123&redirect_uri=..."

      iex> Mercadopago.OAuth.authorization_url("https://myapp.com/callback", state: "abc123")
      "https://auth.mercadopago.com/authorization?client_id=123&redirect_uri=...&state=abc123"

  """
  @spec authorization_url(String.t(), keyword()) :: String.t()
  def authorization_url(redirect_uri, opts \\ []) do
    config = Mercadopago.Config.get()

    params = %{
      "client_id" => config.client_id,
      "redirect_uri" => redirect_uri,
      "response_type" => Keyword.get(opts, :response_type, "code")
    }

    params =
      case Keyword.get(opts, :state) do
        nil -> params
        state -> Map.put(params, "state", state)
      end

    @auth_url <> "?" <> URI.encode_query(params)
  end

  @doc """
  Exchanges an authorization code for access and refresh tokens.

  Call this function in your OAuth callback handler after Mercado Pago
  redirects the user back to your application with the authorization code.

  ## Parameters

    - `code` - The authorization code received from Mercado Pago callback
    - `redirect_uri` - Must be the same redirect_uri used in `authorization_url/2`

  ## Returns

    - `{:ok, tokens}` - Map containing:
      - `access_token` - Token to make API calls (expires in ~6 hours)
      - `refresh_token` - Token to refresh the access_token (expires in 6 months)
      - `expires_in` - Seconds until access_token expires
      - `user_id` - Mercado Pago user ID of the authorized user
      - `public_key` - Public key for frontend operations
      - `token_type` - Usually "Bearer"
      - `scope` - Granted permissions

    - `{:error, reason}` - Error tuple with reason

  ## Examples

      iex> Mercadopago.OAuth.exchange_code("TG-xxx-xxx", "https://myapp.com/callback")
      {:ok, %{access_token: "APP_USR-xxx", refresh_token: "TG-xxx", ...}}

  """
  @spec exchange_code(String.t(), String.t()) ::
          {:ok, map()} | {:error, atom() | String.t()}
  def exchange_code(code, redirect_uri) do
    config = Mercadopago.Config.get()

    params = %{
      "client_id" => config.client_id,
      "client_secret" => config.client_secret,
      "grant_type" => "authorization_code",
      "code" => code,
      "redirect_uri" => redirect_uri
    }

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Accept", "application/json"}
    ]

    body = URI.encode_query(params)

    case HTTPoison.post(@token_url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        tokens = Poison.decode!(response_body, keys: :atoms)
        Logger.info("[Mercadopago.OAuth] Successfully exchanged code for tokens")
        {:ok, tokens}

      {:ok, %HTTPoison.Response{status_code: 400, body: response_body}} ->
        error = Poison.decode!(response_body)
        Logger.error("[Mercadopago.OAuth] Bad request: #{inspect(error)}")
        {:error, error["error"] || :bad_request}

      {:ok, %HTTPoison.Response{status_code: 401, body: response_body}} ->
        error = Poison.decode!(response_body)
        Logger.error("[Mercadopago.OAuth] Unauthorized: #{inspect(error)}")
        {:error, :unauthorized}

      {:ok, %HTTPoison.Response{status_code: status, body: response_body}} ->
        Logger.error("[Mercadopago.OAuth] Unexpected status #{status}: #{response_body}")
        {:error, :unexpected_response}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("[Mercadopago.OAuth] HTTP error: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Refreshes an expired access_token using a refresh_token.

  Access tokens expire after ~6 hours. Use this function to get a new access_token
  without requiring the user to re-authorize your application.

  Note: The refresh_token itself expires after 6 months. After that, the user
  must go through the authorization flow again.

  ## Parameters

    - `refresh_token` - The refresh_token obtained from `exchange_code/2` or a previous refresh

  ## Returns

    - `{:ok, tokens}` - Map containing new tokens (same structure as `exchange_code/2`)
    - `{:error, reason}` - Error tuple

  ## Examples

      iex> Mercadopago.OAuth.refresh_token("TG-xxx-xxx")
      {:ok, %{access_token: "APP_USR-new-xxx", refresh_token: "TG-new-xxx", ...}}

  """
  @spec refresh_token(String.t()) :: {:ok, map()} | {:error, atom() | String.t()}
  def refresh_token(refresh_token) do
    config = Mercadopago.Config.get()

    params = %{
      "client_id" => config.client_id,
      "client_secret" => config.client_secret,
      "grant_type" => "refresh_token",
      "refresh_token" => refresh_token
    }

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Accept", "application/json"}
    ]

    body = URI.encode_query(params)

    case HTTPoison.post(@token_url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        tokens = Poison.decode!(response_body, keys: :atoms)
        Logger.info("[Mercadopago.OAuth] Successfully refreshed tokens")
        {:ok, tokens}

      {:ok, %HTTPoison.Response{status_code: 400, body: response_body}} ->
        error = Poison.decode!(response_body)
        Logger.error("[Mercadopago.OAuth] Bad request during refresh: #{inspect(error)}")
        {:error, error["error"] || :bad_request}

      {:ok, %HTTPoison.Response{status_code: 401, body: response_body}} ->
        error = Poison.decode!(response_body)
        Logger.error("[Mercadopago.OAuth] Unauthorized during refresh: #{inspect(error)}")
        {:error, :unauthorized}

      {:ok, %HTTPoison.Response{status_code: status, body: response_body}} ->
        Logger.error("[Mercadopago.OAuth] Unexpected status #{status}: #{response_body}")
        {:error, :unexpected_response}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("[Mercadopago.OAuth] HTTP error during refresh: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Checks if a token response indicates the access_token is expired or will expire soon.

  ## Parameters

    - `expires_at` - DateTime when the token expires (you should store this in your DB)
    - `buffer_seconds` - Optional buffer time in seconds (default: 300 = 5 minutes)

  ## Returns

    - `true` if token is expired or will expire within buffer time
    - `false` if token is still valid

  ## Examples

      iex> expires_at = DateTime.add(DateTime.utc_now(), 100, :second)
      iex> Mercadopago.OAuth.token_expired?(expires_at)
      true  # Will expire in 100 seconds, less than 300 second buffer

      iex> expires_at = DateTime.add(DateTime.utc_now(), 3600, :second)
      iex> Mercadopago.OAuth.token_expired?(expires_at)
      false  # Still has 1 hour

  """
  @spec token_expired?(DateTime.t(), non_neg_integer()) :: boolean()
  def token_expired?(expires_at, buffer_seconds \\ 300) do
    now = DateTime.utc_now()
    buffer_time = DateTime.add(now, buffer_seconds, :second)
    DateTime.compare(expires_at, buffer_time) == :lt
  end

  @doc """
  Calculates the expiration DateTime from an expires_in value.

  Use this when storing tokens to calculate when they will expire.

  ## Parameters

    - `expires_in` - Number of seconds until expiration (from token response)

  ## Returns

    - DateTime when the token will expire

  ## Examples

      iex> {:ok, tokens} = Mercadopago.OAuth.exchange_code(code, redirect_uri)
      iex> expires_at = Mercadopago.OAuth.calculate_expiry(tokens.expires_in)
      ~U[2024-01-15 18:30:00Z]

  """
  @spec calculate_expiry(non_neg_integer()) :: DateTime.t()
  def calculate_expiry(expires_in) do
    DateTime.add(DateTime.utc_now(), expires_in, :second)
  end
end
