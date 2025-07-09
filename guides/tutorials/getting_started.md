# Getting Started with IbkrApi

This tutorial will guide you through the process of setting up and using the IbkrApi library to interact with Interactive Brokers' Client Portal API.

## Prerequisites

Before you begin, make sure you have:

1. An Interactive Brokers account
2. The Client Portal Gateway running locally or on a server
3. Elixir 1.15 or later

## Installation

Add `ibkr_api` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ibkr_api, "~> 0.1.0"}
  ]
end
```

Then run:

```bash
mix deps.get
```

## Configuration

Configure the library in your application's configuration file (`config/config.exs`):

```elixir
config :ibkr_api,
  base_url: "http://localhost:5000/v1/api",  # Default Client Portal Gateway URL
  timeout: 30_000  # Request timeout in milliseconds
```

You can override these settings in your environment-specific configuration files.

## Starting the Client Portal Gateway

Before using the library, you need to start the Interactive Brokers Client Portal Gateway:

### Prerequisites

1. **Java Runtime Environment (JRE)**: The gateway requires Java 8 update 192 or later. Check if Java is installed:
   ```bash
   java -version
   ```
   If not installed, download from the [official Java website](https://www.java.com/en/download/)

### Download and Setup

2. **Download the Client Portal Gateway**:
   - [Standard Release](https://download2.interactivebrokers.com/portal/clientportal.gw.zip) (recommended)
   - [Beta Release](https://download2.interactivebrokers.com/portal/clientportal.beta.gw.zip) (if you experience issues with standard)

3. **Extract and run the gateway**:
   ```bash
   # Extract the downloaded file
   unzip clientportal.gw.zip
   cd clientportal.gw
   
   # On Unix/Linux/macOS:
   bin/run.sh root/conf.yaml
   
   # On Windows:
   bin\run.bat root\conf.yaml
   ```

**Important Notes:**
- The gateway must run on the same machine where you'll make API calls
- Default port is 5000 (configurable in `root/conf.yaml`)
- You must authenticate through the browser on the same machine

## Basic Usage

### Establishing a Connection

First, you need to authenticate with the IBKR Client Portal API:

```elixir
# Check if the server is running and authenticate
{:ok, response} = IbkrApi.ClientPortal.Auth.ping_server()

# If you need to reauthenticate
{:ok, _} = IbkrApi.ClientPortal.Auth.reauthenticate()
```

### Listing Accounts

Once authenticated, you can list your accounts:

```elixir
{:ok, accounts} = IbkrApi.ClientPortal.Account.list_accounts()

# Print account IDs
accounts |> Enum.each(fn account -> IO.puts(account.account_id) end)
```

### Getting Account Information

You can retrieve detailed information about a specific account:

```elixir
account_id = "U1234567"  # Replace with your actual account ID
{:ok, summary} = IbkrApi.ClientPortal.Account.account_summary(account_id)

# Print available funds
IO.puts("Available funds: #{summary.available_funds}")
```

## Next Steps

Now that you've set up the library and made your first API calls, you can:

1. Learn more about [Authentication](authentication.html) processes
2. Explore [Account Management](../how-to/account_management.html) operations
3. Start [Trading](../how-to/trading.html) with the API

For a complete reference of all available functions, check the [API Reference](../reference/api_reference.html).
