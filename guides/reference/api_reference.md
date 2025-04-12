# API Reference

This reference guide provides detailed information about all modules and functions available in the IbkrApi library.

## Core Modules

### IbkrApi

`IbkrApi` module that serves as the entry point to the library.

### IbkrApi.Config

`IbkrApi.Config` module for configuration management.

```elixir
# Get the base URL for API requests
base_url = IbkrApi.Config.base_url()
```

### IbkrApi.HTTP

`IbkrApi.HTTP` module for making requests to the Interactive Brokers Client Portal API.

```elixir
# Make a GET request
{:ok, response} = IbkrApi.HTTP.get("https://localhost:5000/v1/api/endpoint")

# Make a POST request with a body
body = %{key: "value"}
{:ok, response} = IbkrApi.HTTP.post("https://localhost:5000/v1/api/endpoint", body)
```

## Client Portal Modules

### IbkrApi.ClientPortal.Auth

`IbkrApi.ClientPortal.Auth` module for authentication and session management.

#### Functions

| Function | Description | Parameters | Return Value |
|----------|-------------|------------|--------------|
| `ping_server/0` | Checks server connectivity and authentication status | None | `{:ok, %PingServerResponse{}}` or `{:error, reason}` |
| `reauthenticate/0` | Attempts to reauthenticate an expired session | None | `{:ok, %ReauthenticateResponse{}}` or `{:error, reason}` |
| `end_session/0` | Ends the current session | None | `{:ok, %EndSessionResponse{}}` or `{:error, reason}` |
| `validate_sso/0` | Validates Single Sign-On status | None | `{:ok, %ValidateSSOResponse{}}` or `{:error, reason}` |
| `check_auth_status/0` | Checks the current authentication status | None | `{:ok, %CheckAuthStatusResponse{}}` or `{:error, reason}` |

### IbkrApi.ClientPortal.Account

`IbkrApi.ClientPortal.Account` module for managing account information and operations.

#### Functions

| Function | Description | Parameters | Return Value |
|----------|-------------|------------|--------------|
| `list_accounts/0` | Lists all portfolio accounts | None | `{:ok, [%Account{}]}` or `{:error, reason}` |
| `list_sub_accounts/0` | Lists all sub-accounts | None | `{:ok, [%SubAccount{}]}` or `{:error, reason}` |
| `list_large_sub_accounts/1` | Lists sub-accounts with pagination | `page` (String) | `{:ok, %LargeSubAccounts{}}` or `{:error, reason}` |
| `account_info/1` | Gets account metadata | `account_id` (String) | `{:ok, %Account{}}` or `{:error, reason}` |
| `account_summary/1` | Gets account summary | `account_id` (String) | `{:ok, %AccountSummary{}}` or `{:error, reason}` |
| `account_ledger/1` | Gets account ledger | `account_id` (String) | `{:ok, %AccountLedger{}}` or `{:error, reason}` |
| `list_brokerage_accounts/0` | Lists all brokerage accounts | None | `{:ok, %BrokerageAccountsResponse{}}` or `{:error, reason}` |
| `switch_account/1` | Switches the active account | `acctId` (String) | `{:ok, %SwitchAccountResponse{}}` or `{:error, reason}` |
| `get_pnl/0` | Gets profit and loss information | None | `{:ok, %PnLResponse{}}` or `{:error, reason}` |

### IbkrApi.ClientPortal.Contract

`IbkrApi.ClientPortal.Contract` module for managing financial instruments and contracts.

#### Functions

| Function | Description | Parameters | Return Value |
|----------|-------------|------------|--------------|
| `search_by_symbol/1` | Searches for contracts by symbol | `symbol` (String) | `{:ok, [%Contract{}]}` or `{:error, reason}` |
| `get_contract_details/1` | Gets detailed information for a contract | `conid` (Integer) | `{:ok, %ContractDetails{}}` or `{:error, reason}` |
| `get_contract_info/1` | Gets basic information for a contract | `conid` (Integer) | `{:ok, %ContractInfo{}}` or `{:error, reason}` |

### IbkrApi.ClientPortal.Order

`IbkrApi.ClientPortal.Order` module for managing order placement and monitoring.

#### Functions

| Function | Description | Parameters | Return Value |
|----------|-------------|------------|--------------|
| `place_order/1` | Places a new order | `order_params` (Map) | `{:ok, %OrderResponse{}}` or `{:error, reason}` |
| `modify_order/2` | Modifies an existing order | `order_id` (String), `order_params` (Map) | `{:ok, %OrderResponse{}}` or `{:error, reason}` |
| `cancel_order/1` | Cancels an order | `order_id` (String) | `{:ok, %CancelResponse{}}` or `{:error, reason}` |
| `get_live_orders/0` | Gets all live orders | None | `{:ok, [%Order{}]}` or `{:error, reason}` |
| `get_order_status/1` | Gets status of a specific order | `order_id` (String) | `{:ok, %Order{}}` or `{:error, reason}` |

### IbkrApi.ClientPortal.Profile

`IbkrApi.ClientPortal.Profile` module for managing user profile information.

#### Functions

| Function | Description | Parameters | Return Value |
|----------|-------------|------------|--------------|
| `get_profile/0` | Gets user profile information | None | `{:ok, %Profile{}}` or `{:error, reason}` |
| `update_profile/1` | Updates user profile | `profile_params` (Map) | `{:ok, %UpdateProfileResponse{}}` or `{:error, reason}` |

### IbkrApi.ClientPortal.Trade

`IbkrApi.ClientPortal.Trade` module for managing trade executions and history.

#### Functions

| Function | Description | Parameters | Return Value |
|----------|-------------|------------|--------------|
| `get_executions/1` | Gets trade executions for an account | `account_id` (String) | `{:ok, [%Execution{}]}` or `{:error, reason}` |

## Error Handling

All API functions return `{:ok, result}` on success and `{:error, reason}` on failure. The error reason is typically an `ErrorMessage` struct with the following fields:

```elixir
%ErrorMessage{
  code: "1234",       # Error code
  message: "Error message description",
  description: "Detailed error description"
}
```

## Common Error Codes

| Code | Description |
|------|-------------|
| "1015" | Account not found or not authorized |
| "1021" | Session expired, please reauthenticate |
| "1022" | Invalid contract ID |
| "1100" | Invalid order parameters |
| "1101" | Insufficient funds |
| "2000" | Server error |

## Related Resources

- [Getting Started](../tutorials/getting_started.html)
- [Authentication](../tutorials/authentication.html)
- [Account Management](../how-to/account_management.html)
- [Trading](../how-to/trading.html)
- [Architecture](../explanations/architecture.html)
