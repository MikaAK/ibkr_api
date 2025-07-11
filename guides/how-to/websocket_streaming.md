# WebSocket Streaming Guide

This guide explains how to use the IBKR WebSocket API for real-time streaming data including market data, order updates, and portfolio P&L.

> #### Prerequisites {: .info}
>
> Before using WebSocket streaming, ensure you have:
>
> 1. **IBKR Client Portal Gateway running** - Download and start the gateway from:
>    - [Standard Release](https://download2.interactivebrokers.com/portal/clientportal.gw.zip)
>    - [Beta Release](https://download2.interactivebrokers.com/portal/clientportal.beta.gw.zip)
>
> 2. **Valid IBKR login** - Log in through the gateway web interface (usually https://localhost:5000)
>
> 3. **Market data subscriptions** - Ensure your account has appropriate market data permissions
>
> 4. **Java 8 Update 192+** - Required to run the Client Portal Gateway

## Quick Start

### 1. Create Your WebSocket Client

```elixir
defmodule MyTradingBot do
  use IbkrApi.Websocket
  require Logger

  def handle_event({:market_data, data}, state) do
    Logger.info("Price update for #{data.contract_id}: #{data.fields["31"]}")
    # Your trading logic here
    {:ok, state}
  end

  def handle_event({:order_update, order}, state) do
    Logger.info("Order update: #{inspect(order.data)}")
    # Handle order fills, cancellations, etc.
    {:ok, state}
  end

  def handle_event({:pnl_update, pnl}, state) do
    Logger.info("P&L: Daily=#{pnl.daily_pnl}, Unrealized=#{pnl.unrealized_pnl}")
    # Monitor portfolio performance
    {:ok, state}
  end

  def handle_event(_event, state) do
    {:ok, state}
  end
end
```

### 2. Start the Client and Subscribe

```elixir
# Start the WebSocket client
{:ok, pid} = MyTradingBot.start_link(%{})

# Subscribe to market data for Apple (AAPL)
# First, get the contract ID
{:ok, contracts} = IbkrApi.ClientPortal.Contract.search_contracts("AAPL")
contract_id = hd(contracts).contract_id

# Subscribe to last price (31) and percent change (83)
MyTradingBot.subscribe_to_market_data(pid, [contract_id], ["31", "83"])

# Subscribe to order updates
MyTradingBot.subscribe_to_order_updates(pid)

# Subscribe to P&L updates
MyTradingBot.subscribe_to_pnl(pid)
```

## Market Data Streaming

### Field IDs

Common field IDs for market data subscriptions:

| Field ID | Description |
|----------|-------------|
| "31" | Last price |
| "83" | Percent change |
| "84" | High |
| "85" | Low |
| "86" | Volume |
| "87" | Close |
| "88" | Bid |
| "89" | Ask |
| "7295" | Market cap |
| "7296" | Company name |

### Subscription Options

```elixir
# Basic subscription
MyTradingBot.subscribe_to_market_data(pid, [contract_id], ["31", "83"])

# With custom options
MyTradingBot.subscribe_to_market_data(pid, [contract_id], ["31", "83"], %{
  tempo: 500,      # Update every 500ms (default: 1000)
  snapshot: true   # Request initial snapshot (default: true)
})

# Multiple contracts
contract_ids = [8314, 265598, 76792]  # IBM, AAPL, MSFT
MyTradingBot.subscribe_to_market_data(pid, contract_ids, ["31", "83"])
```

### Handling Market Data

```elixir
def handle_event({:market_data, data}, state) do
  %{
    contract_id: contract_id,
    fields: fields,
    timestamp: timestamp
  } = data

  # Extract specific fields
  last_price = Map.get(fields, "31")
  percent_change = Map.get(fields, "83")
  volume = Map.get(fields, "86")

  # Your logic here
  if last_price do
    Logger.info("#{contract_id}: $#{last_price}")
  end

  {:ok, state}
end
```

## Order Updates

### Subscribing to Orders

```elixir
# Subscribe to all order updates for your accounts
MyTradingBot.subscribe_to_order_updates(pid)
```

### Handling Order Updates

```elixir
def handle_event({:order_update, order}, state) do
  %{
    topic: topic,
    data: order_data,
    timestamp: timestamp
  } = order

  # Extract order information
  order_id = Map.get(order_data, "orderId")
  status = Map.get(order_data, "status")
  filled_quantity = Map.get(order_data, "filledQuantity")

  case status do
    "Filled" ->
      Logger.info("Order #{order_id} filled: #{filled_quantity} shares")
      # Handle fill logic
    
    "Cancelled" ->
      Logger.info("Order #{order_id} cancelled")
      # Handle cancellation logic
    
    _ ->
      Logger.info("Order #{order_id} status: #{status}")
  end

  {:ok, state}
end
```

## Portfolio P&L Updates

### Subscribing to P&L

```elixir
# Subscribe to portfolio P&L updates
MyTradingBot.subscribe_to_pnl(pid)
```

### Handling P&L Updates

```elixir
def handle_event({:pnl_update, pnl}, state) do
  %{
    daily_pnl: daily_pnl,
    unrealized_pnl: unrealized_pnl,
    data: full_data,
    timestamp: timestamp
  } = pnl

  # Monitor portfolio performance
  total_pnl = (daily_pnl || 0) + (unrealized_pnl || 0)
  
  Logger.info("Portfolio P&L: $#{total_pnl}")
  
  # Risk management logic
  if total_pnl < -1000 do
    Logger.warn("Portfolio down $#{abs(total_pnl)} - consider risk management")
  end

  {:ok, state}
end
```

## Advanced Usage

### Custom WebSocket URL

```elixir
# Connect to remote gateway
{:ok, pid} = MyTradingBot.start_link(%{}, url: "wss://api.ibkr.com/v1/api/ws")

# Custom SSL options
{:ok, pid} = MyTradingBot.start_link(%{}, 
  url: "wss://localhost:5000/v1/api/ws",
  ssl_opts: [verify: :verify_none]
)
```

### Disable Automatic Heartbeat

```elixir
# Disable automatic heartbeat and send manually
{:ok, pid} = MyTradingBot.start_link(%{}, heartbeat: false)

# Send heartbeat manually
MyTradingBot.send_heartbeat(pid)
```

### State Management

```elixir
defmodule StatefulTradingBot do
  use IbkrApi.Websocket

  def handle_event({:market_data, data}, state) do
    # Update state with new price data
    new_state = Map.put(state, :last_price, Map.get(data.fields, "31"))
    
    # Make trading decisions based on state
    if should_trade?(new_state) do
      place_order(data.contract_id, new_state)
    end
    
    {:ok, new_state}
  end

  defp should_trade?(state) do
    # Your trading logic here
    false
  end

  defp place_order(contract_id, state) do
    # Place order using the regular API
    IbkrApi.ClientPortal.Order.place_order(%{
      conid: contract_id,
      orderType: "MKT",
      side: "BUY",
      quantity: 100
    })
  end
end
```

## Error Handling

### Connection Issues

```elixir
defmodule RobustTradingBot do
  use IbkrApi.Websocket

  def handle_disconnect(%{reason: reason}, state) do
    Logger.error("WebSocket disconnected: #{inspect(reason)}")
    
    # Implement reconnection logic
    Process.send_after(self(), :reconnect, 5000)
    
    {:ok, state}
  end

  def handle_info(:reconnect, state) do
    Logger.info("Attempting to reconnect...")
    # Reconnection logic here
    {:ok, state}
  end
end
```

### Message Parsing Errors

```elixir
def handle_event({:unknown, data}, state) do
  Logger.warn("Unknown message type: #{inspect(data)}")
  {:ok, state}
end

def handle_event({:raw, data}, state) do
  Logger.warn("Raw message without topic: #{inspect(data)}")
  {:ok, state}
end
```

## Rate Limits and Best Practices

### Rate Limits

- **Market Data**: Maximum ~5 concurrent subscriptions per session
- **Connection**: One WebSocket connection per session
- **Heartbeat**: Send every 10 seconds to maintain connection

> #### Rate Limits {: .warning}
>
> IBKR limits market data subscriptions to approximately **5 concurrent streams per session**. Exceeding this limit may result in connection issues or data delays.

## Best Practices

> #### Performance Tips {: .tip}
>
> - **Unsubscribe** from unused streams to free up slots
> - **Batch subscriptions** when possible  
> - **Monitor connection** health with heartbeat
> - **Handle reconnections** gracefully
> - **Use appropriate log levels** (debug for verbose data)

### Example: Rotating Subscriptions

```elixir
defmodule RotatingBot do
  use IbkrApi.Websocket

  def rotate_subscriptions(pid, old_contracts, new_contracts) do
    # Unsubscribe from old contracts
    MyTradingBot.unsubscribe_from_market_data(pid, old_contracts)
    
    # Subscribe to new contracts
    MyTradingBot.subscribe_to_market_data(pid, new_contracts, ["31", "83"])
  end
end
```

## Troubleshooting

### Common Issues

1. **Connection Refused**: Ensure the Client Portal Gateway is running
2. **SSL Errors**: Use `ssl_opts: [verify: :verify_none]` for localhost
3. **No Data**: Check market data subscriptions and trading hours
4. **Authentication**: Ensure you're logged in via the gateway web interface

### Debug Logging

```elixir
# Enable debug logging
Logger.configure(level: :debug)

def handle_event(event, state) do
  Logger.debug("Received event: #{inspect(event)}")
  {:ok, state}
end
```

## Integration with Trading Strategies

### Example: Moving Average Crossover

```elixir
defmodule MACrossoverBot do
  use IbkrApi.Websocket

  def handle_event({:market_data, data}, state) do
    price = Map.get(data.fields, "31")
    
    if price do
      new_state = update_moving_averages(state, data.contract_id, price)
      
      if crossover_signal?(new_state, data.contract_id) do
        execute_trade(data.contract_id, new_state)
      end
      
      {:ok, new_state}
    else
      {:ok, state}
    end
  end

  defp update_moving_averages(state, contract_id, price) do
    # Update price history and calculate moving averages
    # Implementation details...
    state
  end

  defp crossover_signal?(state, contract_id) do
    # Check for MA crossover signal
    # Implementation details...
    false
  end

  defp execute_trade(contract_id, state) do
    # Execute trade via the Order API
    # Implementation details...
  end
end
```

This WebSocket implementation provides a robust foundation for real-time trading applications with the IBKR API.
