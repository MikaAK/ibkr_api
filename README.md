# IbkrApi

[![Hex.pm](https://img.shields.io/hexpm/v/ibkr_api.svg)](https://hex.pm/packages/ibkr_api)
[![Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/ibkr_api)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A comprehensive Elixir client for Interactive Brokers' Client Portal API. This library provides a clean, idiomatic Elixir interface to interact with Interactive Brokers' trading platform.

## Features

- Complete API coverage for Interactive Brokers' Client Portal API
- Authentication and session management
- Account information and portfolio management
- Order placement and management
- Market data and contract information
- Trading operations
- Profile management

## Installation

Add `ibkr_api` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ibkr_api, "~> 0.1.0"}
  ]
end
```

## Quick Start

```elixir
# Authenticate with the IBKR Client Portal API
{:ok, auth_response} = IbkrApi.ClientPortal.Auth.ping_server()

# List your accounts
{:ok, accounts} = IbkrApi.ClientPortal.Account.list_accounts()

# Get account summary
account_id = hd(accounts).account_id
{:ok, summary} = IbkrApi.ClientPortal.Account.account_summary(account_id)
```

## Documentation

- **Tutorials**: Step-by-step guides to get you started
  - [Getting Started](https://hexdocs.pm/ibkr_api/getting_started.html)
  - [Authentication](https://hexdocs.pm/ibkr_api/authentication.html)

- **How-To Guides**: Practical guides for specific tasks
  - [Account Management](https://hexdocs.pm/ibkr_api/account_management.html)
  - [Trading](https://hexdocs.pm/ibkr_api/trading.html)

- **Reference**: Technical information and API details
  - [API Reference](https://hexdocs.pm/ibkr_api/api_reference.html)

- **Explanation**: Background information and concepts
  - [Architecture](https://hexdocs.pm/ibkr_api/architecture.html)

## Prerequisites

To use this library, you need:

1. **Interactive Brokers account** - Active IBKR brokerage account
2. **Java Runtime Environment** - Java 8 update 192 or later for the Client Portal Gateway
3. **Client Portal Gateway** - Download and run locally:
   - [Standard Release](https://download2.interactivebrokers.com/portal/clientportal.gw.zip)
   - [Beta Release](https://download2.interactivebrokers.com/portal/clientportal.beta.gw.zip)
4. **Elixir 1.15 or later**

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
