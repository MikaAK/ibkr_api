# Authentication with IbkrApi

This tutorial explains how to authenticate with the Interactive Brokers Client Portal API using the IbkrApi library.

## Understanding IBKR Authentication

> #### Session-Based Authentication {: .info}
>
> The Interactive Brokers Client Portal API uses a session-based authentication system. Before making API calls, you need to:
>
> 1. **Start the Client Portal Gateway**
> 2. **Authenticate through the gateway's web interface**
> 3. **Maintain your authenticated session**

## Initial Authentication

When you first start the Client Portal Gateway, you need to authenticate through its web interface:

1. **Download and start the gateway**:
   - Download: [Standard Release](https://download2.interactivebrokers.com/portal/clientportal.gw.zip) or [Beta Release](https://download2.interactivebrokers.com/portal/clientportal.beta.gw.zip)
   - Ensure Java 8+ is installed: `java -version`
   - Extract and run: `bin/run.sh root/conf.yaml` (Unix) or `bin\run.bat root\conf.yaml` (Windows)

2. **Authenticate via browser**:
   - Open a browser and navigate to `http://localhost:5000`
   - Log in with your Interactive Brokers credentials
   
   > #### Critical Authentication Requirement {: .warning}
   >
   > Authentication **must** be done on the same machine where the gateway is running. Remote authentication will not work due to security restrictions.

3. After successful login, you can start using the IbkrApi library

## Session Management with IbkrApi

### Checking Authentication Status

To check if your session is still valid:

```elixir
{:ok, status} = IbkrApi.ClientPortal.Auth.check_auth_status()

if status.authenticated do
  IO.puts("Session is active")
else
  IO.puts("Session needs to be re-authenticated")
end
```

### Pinging the Server

The `ping_server/0` function is a convenient way to check both connectivity and authentication status:

```elixir
case IbkrApi.ClientPortal.Auth.ping_server() do
  {:ok, response} ->
    if response.iserver.auth_status.authenticated do
      IO.puts("Connected and authenticated")
    else
      IO.puts("Connected but not authenticated")
    end
  
  {:error, reason} ->
    IO.puts("Connection error: #{inspect(reason)}")
end
```

### Re-authentication Flow

When your session expires, you'll need to re-authenticate. Here's the proper flow:

1. **Check authentication status first**:

```elixir
{:ok, status} = IbkrApi.ClientPortal.Auth.check_auth_status()

case status do
  %IbkrApi.ClientPortal.Auth.CheckAuthStatusResponse{authenticated: false} ->
    # Session expired, need to re-authenticate
    IO.puts("Session expired, re-authenticating...")
    
  %IbkrApi.ClientPortal.Auth.CheckAuthStatusResponse{authenticated: true} ->
    # Session is still valid
    IO.puts("Session is active")
end
```

2. **When authentication is false, follow this sequence**:

```elixir
# Step 1: Call reauthenticate
{:ok, reauth_response} = IbkrApi.ClientPortal.Auth.reauthenticate()

# Step 2: Call validate_sso
{:ok, sso_response} = IbkrApi.ClientPortal.Auth.validate_sso()

IO.puts("Re-authentication complete")
```

3. **Complete re-authentication helper function**:

```elixir
def handle_reauthentication do
  case IbkrApi.ClientPortal.Auth.check_auth_status() do
    {:ok, %IbkrApi.ClientPortal.Auth.CheckAuthStatusResponse{authenticated: false}} ->
      # Session expired, re-authenticate
      with {:ok, _reauth} <- IbkrApi.ClientPortal.Auth.reauthenticate(),
           {:ok, _sso} <- IbkrApi.ClientPortal.Auth.validate_sso() do
        {:ok, :reauthenticated}
      else
        {:error, reason} -> {:error, {:reauthentication_failed, reason}}
      end
      
    {:ok, %IbkrApi.ClientPortal.Auth.CheckAuthStatusResponse{authenticated: true}} ->
      {:ok, :already_authenticated}
      
    {:error, reason} ->
      {:error, {:check_status_failed, reason}}
  end
end
```

**Important Notes:**
- Always call `reauthenticate/0` first, then `validate_sso/0`
- Re-authentication may not work if your session has been expired for too long
- In such cases, you'll need to log in again through the web interface at `http://localhost:5000`

### Validating SSO

For applications using Single Sign-On (SSO):

```elixir
{:ok, sso_info} = IbkrApi.ClientPortal.Auth.validate_sso()

IO.puts("User: #{sso_info.user_name}")
IO.puts("Expires: #{sso_info.expires}")
```

### Ending Your Session

When you're done using the API, it's good practice to end your session:

```elixir
{:ok, _} = IbkrApi.ClientPortal.Auth.end_session()
```

## Authentication Flow in Production

In a production environment, you might want to implement a more robust authentication flow:

```elixir
defmodule MyApp.IbkrAuthManager do
  def ensure_authenticated do
    case IbkrApi.ClientPortal.Auth.check_auth_status() do
      {:ok, %{authenticated: true}} ->
        {:ok, :authenticated}
        
      {:ok, %{authenticated: false}} ->
        # Try to reauthenticate
        case IbkrApi.ClientPortal.Auth.reauthenticate() do
          {:ok, %{message: "Authenticated"}} -> {:ok, :reauthenticated}
          _ -> {:error, :authentication_required}
        end
        
      {:error, reason} ->
        {:error, reason}
    end
  end
end
```

## Session Timeout Considerations

Interactive Brokers sessions typically time out after a period of inactivity. To maintain an active session:

1. Implement a periodic ping to the server (e.g., every 5 minutes)
2. Handle reauthentication automatically when needed
3. Have a fallback mechanism for when reauthentication fails

## Next Steps

Now that you understand how to manage authentication with the IBKR API, you can:

1. Learn about [Account Management](../how-to/account_management.html)
2. Start [Trading](../how-to/trading.html) with the API
3. Explore the [API Reference](../reference/api_reference.html) for more details
