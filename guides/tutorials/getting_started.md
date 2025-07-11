# Getting Started with IbkrApi

This tutorial will guide you through the process of setting up and using the IbkrApi library to interact with Interactive Brokers' Client Portal API.

> #### Prerequisites {: .info}
>
> Before you begin, make sure you have:
>
> 1. **An Interactive Brokers account** with appropriate permissions
> 2. **The Client Portal Gateway** running locally or on a server
> 3. **Elixir 1.15 or later** installed on your system
> 4. **Java 8 Update 192+** for running the Client Portal Gateway

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
  host: "https://localhost",  # Default Client Portal Gateway host
  port: 5000,  # Default Client Portal Gateway port
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

> #### Important Security Notes {: .warning}
>
> - **Same-machine requirement**: The gateway must run on the same machine where you'll make API calls
> - **Default port**: 5000 (configurable in `root/conf.yaml`)
> - **Browser authentication**: You must authenticate through the browser on the same machine
> - **SSL certificates**: The gateway uses self-signed certificates by default

## Basic Usage

### Establishing a Connection

First, you need to authenticate with the IBKR Client Portal API using `IbkrApi.ClientPortal.Auth`:

```elixir
# Check if the server is running and authenticate
{:ok, response} = IbkrApi.ClientPortal.Auth.ping_server()

# If you need to reauthenticate
{:ok, _} = IbkrApi.ClientPortal.Auth.reauthenticate()
```

### Listing Accounts

Once authenticated, you can list your accounts using `IbkrApi.ClientPortal.Portfolio`:

```elixir
{:ok, accounts} = IbkrApi.ClientPortal.Portfolio.list_accounts()

# Print account IDs
accounts |> Enum.each(fn account -> IO.puts(account.account_id) end)
```

### Getting Account Information

You can retrieve detailed information about a specific account using `IbkrApi.ClientPortal.Portfolio`:

```elixir
account_id = "U1234567"  # Replace with your actual account ID
{:ok, summary} = IbkrApi.ClientPortal.Portfolio.account_summary(account_id)

# Access summary data (returns a map with account fields)
IO.inspect(summary, label: "Account Summary")
```

> #### Next Steps {: .tip}
>
> Now that you've set up the library and made your first API calls, you can:
>
> 1. Learn more about [Authentication](authentication.html) processes
> 2. Explore [Account Management](../how-to/account_management.html) operations  
> 3. Start [Trading](../how-to/trading.html) with the API
> 4. Set up [WebSocket Streaming](../how-to/websocket_streaming.html) for real-time data
>
> For a complete reference of all available functions, check the [API Reference](../reference/api_reference.html).
