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

`IbkrApi.HTTP` module for rate-limited HTTP requests to the Interactive Brokers Client Portal API.

```elixir
# Make a GET request
{:ok, response} = IbkrApi.HTTP.get("https://localhost:5000/v1/api/endpoint")

# Make a POST request with a body
body = %{key: "value"}
{:ok, response} = IbkrApi.HTTP.post("https://localhost:5000/v1/api/endpoint", body)

# Make a PUT request
{:ok, response} = IbkrApi.HTTP.put("https://localhost:5000/v1/api/endpoint", body)

# Make a DELETE request
{:ok, response} = IbkrApi.HTTP.delete("https://localhost:5000/v1/api/endpoint")
```

### IbkrApi.Websocket

`IbkrApi.Websocket` module for real-time streaming data from the Interactive Brokers Client Portal API.

```elixir
# Create a WebSocket client module
defmodule MyIbkrClient do
  use IbkrApi.Websocket

  def handle_event({:market_data, data}, state) do
    IO.inspect(data, label: "Market Data")
    {:ok, state}
  end

  def handle_event({:order_update, order}, state) do
    IO.inspect(order, label: "Order Update")
    {:ok, state}
  end

  def handle_event({:pnl_update, pnl}, state) do
    IO.inspect(pnl, label: "P&L Update")
    {:ok, state}
  end

  def handle_event(_event, state) do
    {:ok, state}
  end
end

# Start the WebSocket client
{:ok, pid} = MyIbkrClient.start_link(%{})

# Subscribe to market data
MyIbkrClient.subscribe_to_market_data(pid, [8314], ["31", "83"])

# Subscribe to order updates
MyIbkrClient.subscribe_to_order_updates(pid)

# Subscribe to P&L updates
MyIbkrClient.subscribe_to_pnl(pid)
```

#### Functions

| Function | Description | Parameters | Return Value |
|----------|-------------|------------|-------------|
| `start_link/1` | Starts the WebSocket client | `state` (Map) | `{:ok, pid}` or `{:error, reason}` |
| `subscribe_to_market_data/3` | Subscribes to real-time market data | `pid`, `conids` (List), `fields` (List) | `:ok` |
| `subscribe_to_order_updates/1` | Subscribes to order status updates | `pid` | `:ok` |
| `subscribe_to_pnl/1` | Subscribes to portfolio P&L updates | `pid` | `:ok` |
| `unsubscribe_from_market_data/2` | Unsubscribes from market data | `pid`, `conids` (List) | `:ok` |
| `unsubscribe_from_order_updates/1` | Unsubscribes from order updates | `pid` | `:ok` |
| `unsubscribe_from_pnl/1` | Unsubscribes from P&L updates | `pid` | `:ok` |

## Client Portal Modules

### IbkrApi.ClientPortal.Auth

`IbkrApi.ClientPortal.Auth` module for authentication and session management.

#### Functions

| Function | Description | Parameters | Return Value |
|----------|-------------|------------|-------------|
| `ping_server/0` | Checks server connectivity and authentication status | None | `{:ok, %PingServerResponse{}}` or `{:error, reason}` |
| `reauthenticate/0` | Attempts to reauthenticate an expired session | None | `{:ok, %ReauthenticateResponse{}}` or `{:error, reason}` |
| `end_session/0` | Ends the current session | None | `{:ok, %EndSessionResponse{}}` or `{:error, reason}` |
| `validate_sso/0` | Validates Single Sign-On status | None | `{:ok, %ValidateSSOResponse{}}` or `{:error, reason}` |
| `check_auth_status/0` | Checks the current authentication status | None | `{:ok, %CheckAuthStatusResponse{}}` or `{:error, reason}` |

### IbkrApi.ClientPortal.Portfolio

`IbkrApi.ClientPortal.Portfolio` module for managing account information, positions, and portfolio operations.

#### Functions

| Function | Description | Parameters | Return Value |
|----------|-------------|------------|-------------|
| `list_accounts/0` | Lists all portfolio accounts | None | `{:ok, [%Account{}]}` or `{:error, reason}` |
| `list_sub_accounts/0` | Lists all sub-accounts | None | `{:ok, [%SubAccount{}]}` or `{:error, reason}` |
| `account_info/1` | Gets account metadata | `account_id` (String) | `{:ok, %Account{}}` or `{:error, reason}` |
| `account_summary/1` | Gets account summary with dynamic fields | `account_id` (String) | `{:ok, %AccountSummary{}}` or `{:error, reason}` |
| `account_ledger/1` | Gets account ledger by currency | `account_id` (String) | `{:ok, %AccountLedger{}}` or `{:error, reason}` |
| `list_brokerage_accounts/0` | Lists all brokerage accounts | None | `{:ok, %BrokerageAccountsResponse{}}` or `{:error, reason}` |
| `switch_account/1` | Switches the active account | `acct_id` (String) | `{:ok, %SwitchAccountResponse{}}` or `{:error, reason}` |
| `get_pnl/0` | Gets profit and loss information | None | `{:ok, %PnLResponse{}}` or `{:error, reason}` |
| `account_allocation/1` | Gets account allocation by group | `account_id` (String) | `{:ok, [%Allocation{}]}` or `{:error, reason}` |
| `all_accounts_allocation/1` | Gets allocation for all accounts | `account_id` (String) | `{:ok, [%Allocation{}]}` or `{:error, reason}` |
| `portfolio_positions/3` | Gets portfolio positions | `account_id`, `page_id`, `model` | `{:ok, [%Position{}]}` or `{:error, reason}` |
| `position_by_conid/2` | Gets position by contract ID | `account_id`, `conid` | `{:ok, [%Position{}]}` or `{:error, reason}` |
| `invalidate_positions_cache/1` | Invalidates the positions cache | `account_id` | `{:ok, %{}}` or `{:error, reason}` |

### IbkrApi.ClientPortal.Contract

`IbkrApi.ClientPortal.Contract` module for managing financial instruments and contracts.

#### Functions

| Function | Parameters | Description | Return |
|----------|------------|-------------|--------|
| `get_contract_info/2` | `conid`, `opts` | Get detailed contract information | `{:ok, [SecdefInfo.t()]}` |
| `get_trading_schedule/3` | `asset_class`, `symbol`, `opts` | Get trading schedule for symbol | `{:ok, TradingSchedule.t()}` |
| `security_stocks_by_symbol/1` | `symbol` | Get stock security definition | `{:ok, StockSecurityDefinition.t()}` |
| `get_exchange_rate/2` | `source`, `target` | Get currency exchange rate | `{:ok, float()}` |
| `get_available_currency_pairs/1` | `currency` | Get available currency pairs | `{:ok, [CurrencyPair.t()]}` |
| `search_contracts/2` | `symbol`, `opts` | Search contracts by symbol | `{:ok, [SearchContract.t()]}` |
| `get_strikes/4` | `contract_id`, `sec_type`, `month`, `opts` | Get option strikes for contract | `{:ok, StrikesResponse.t()}` |
| `get_strikes/1` | `symbol` | Get strikes for symbol (convenience) | `{:ok, StrikesResponse.t()}` |
| `contract_details/1` | `conid` | Get contract details | `{:ok, map()}` |
| `get_stock_security_definition/1` | `symbol` | Get stock security definition | `{:ok, map()}` |
| `get_options_for_symbol/2` | `symbol`, `opts` | Get options for symbol | `{:ok, map()}` |

### IbkrApi.ClientPortal.MarketData

Real-time and historical market data.

| Function | Parameters | Description | Return |
|----------|------------|-------------|--------|
| `get_market_data_snapshot/2` | `conids`, `opts` | Get live market data snapshots | `{:ok, [MarketDataSnapshot.t()]}` |
| `get_historical_data/4` | `conid`, `period`, `bar`, `opts` | Get historical market data | `{:ok, [HistoricalBar.t()]}` |

**MarketDataSnapshot Fields:**
- Price fields: `last_price`, `bid_price`, `ask_price`, `high`, `low`, `open`, `close`
- Volume fields: `volume`, `bid_size`, `ask_size`, `last_size`, `average_volume`
- Change fields: `change`, `change_percent`, `change_since_open`
- P&L fields: `market_value`, `unrealized_pnl`, `daily_pnl`, `realized_pnl`
- Greeks (options): `delta`, `gamma`, `theta`, `vega`
- Company info: `company_name`, `symbol`, `industry`, `category`
- Financial metrics: `market_cap`, `pe_ratio`, `eps`, `beta`

### IbkrApi.ClientPortal.Order

`IbkrApi.ClientPortal.Order` module for managing order placement and monitoring.

#### Functions

| Function | Parameters | Description | Return |
|----------|------------|-------------|--------|
| `get_live_orders/0` | - | Get all live orders | `{:ok, OrderResponse.t()}` |
| `get_order_status/1` | `order_id` | Get order status | `{:ok, OrderStatusResponse.t()}` |
| `place_orders/2` | `account_id`, `orders` | Place new orders | `{:ok, [OrderPlacementResponse.t()]}` |
| `place_orders_for_fa/2` | `fa_group`, `orders` | Place orders for FA group | `{:ok, [OrderPlacementResponse.t()]}` |
| `modify_order/3` | `account_id`, `order_id`, `request` | Modify existing order | `{:ok, ModifyOrderResponse.t()}` |
| `cancel_order/2` | `account_id`, `order_id` | Cancel order | `{:ok, CancelOrderResponse.t()}` |
| `preview_order/2` | `account_id`, `orders` | Preview order before placement | `{:ok, OrderPreviewResponse.t()}` |
| `reply_to_order_query/2` | `reply_id`, `confirmed` | Reply to order confirmation query | `{:ok, OrderReplyResponse.t()}` |

**Order Types Supported:**
- Market orders (`MKT`)
- Limit orders (`LMT`) 
- Stop orders (`STP`)
- Stop-limit orders (`STP LMT`)
- Trailing stop orders with amount or percentage
- Adaptive orders for better execution

### IbkrApi.ClientPortal.Trade

Trade execution history and details.

| Function | Parameters | Description | Return |
|----------|------------|-------------|--------|
| `list_trades/0` | - | Get all trade executions | `{:ok, [Trade.t()]}` |

**Trade Fields:**
- Execution info: `execution_id`, `trade_time`, `size`, `price`
- Order info: `order_description`, `order_ref`, `side`
- Contract info: `symbol`, `conid`, `sec_type`, `company_name`
- Financial info: `commission`, `net_amount`, `position`
- Account info: `account`, `account_code`, `clearing_id`

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
