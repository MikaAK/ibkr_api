# Trading with IbkrApi

This guide covers how to perform trading operations using the IbkrApi library, including placing orders, modifying orders, and retrieving order status.

## Finding Contracts

Before placing an order, you need to find the contract you want to trade:

```elixir
# Search for a stock by symbol
symbol = "AAPL"
{:ok, contracts} = IbkrApi.ClientPortal.Contract.search_by_symbol(symbol)

# Process the search results
contracts |> Enum.each(fn contract ->
  IO.puts("Contract: #{contract.symbol}")
  IO.puts("Description: #{contract.description}")
  IO.puts("Contract ID: #{contract.conid}")
  IO.puts("---")
end)

# Get the contract ID for use in orders
contract_id = List.first(contracts).conid
```

## Placing Orders

### Market Order

To place a simple market order:

```elixir
# Define the order parameters
order_params = %{
  acctId: "U1234567",  # Replace with your account ID
  conid: 265598,       # Contract ID for the instrument
  orderType: "MKT",    # Market order
  side: "BUY",         # BUY or SELL
  quantity: 100,       # Number of shares/contracts
  tif: "DAY"           # Time in force
}

# Place the order
{:ok, order_response} = IbkrApi.ClientPortal.Order.place_order(order_params)

# Get the order ID for future reference
order_id = order_response.order_id
IO.puts("Order placed with ID: #{order_id}")
```

### Limit Order

For a limit order with a specific price:

```elixir
limit_order_params = %{
  acctId: "U1234567",
  conid: 265598,
  orderType: "LMT",    # Limit order
  side: "BUY",
  quantity: 100,
  price: 150.25,       # Limit price
  tif: "DAY"
}

{:ok, order_response} = IbkrApi.ClientPortal.Order.place_order(limit_order_params)
```

### Stop Order

For a stop order:

```elixir
stop_order_params = %{
  acctId: "U1234567",
  conid: 265598,
  orderType: "STP",    # Stop order
  side: "SELL",
  quantity: 100,
  auxPrice: 145.50,    # Stop price
  tif: "GTC"           # Good Till Canceled
}

{:ok, order_response} = IbkrApi.ClientPortal.Order.place_order(stop_order_params)
```

## Checking Order Status

To check the status of your orders:

```elixir
# Get all live orders
{:ok, orders} = IbkrApi.ClientPortal.Order.get_live_orders()

# Process the orders
orders |> Enum.each(fn order ->
  IO.puts("Order ID: #{order.order_id}")
  IO.puts("Status: #{order.status}")
  IO.puts("Contract: #{order.symbol}")
  IO.puts("Side: #{order.side}")
  IO.puts("Quantity: #{order.quantity}")
  IO.puts("---")
end)
```

## Modifying Orders

To modify an existing order:

```elixir
# Order ID from the original order placement
order_id = "1234567890"

# New parameters for the order
modified_params = %{
  acctId: "U1234567",
  conid: 265598,
  orderType: "LMT",
  side: "BUY",
  quantity: 150,       # Updated quantity
  price: 148.75,       # Updated price
  tif: "DAY"
}

{:ok, modified_response} = IbkrApi.ClientPortal.Order.modify_order(order_id, modified_params)
```

## Canceling Orders

To cancel an order:

```elixir
order_id = "1234567890"
{:ok, cancel_response} = IbkrApi.ClientPortal.Order.cancel_order(order_id)

if cancel_response.success do
  IO.puts("Order successfully canceled")
else
  IO.puts("Failed to cancel order: #{cancel_response.error}")
end
```

## Retrieving Executions

To get information about executed trades:

```elixir
# Get executions for a specific account
account_id = "U1234567"
{:ok, executions} = IbkrApi.ClientPortal.Trade.get_executions(account_id)

# Process the executions
executions |> Enum.each(fn execution ->
  IO.puts("Execution ID: #{execution.execution_id}")
  IO.puts("Symbol: #{execution.symbol}")
  IO.puts("Side: #{execution.side}")
  IO.puts("Quantity: #{execution.quantity}")
  IO.puts("Price: #{execution.price}")
  IO.puts("Time: #{execution.time}")
  IO.puts("---")
end)
```

## Order Types and Parameters

Interactive Brokers supports a wide range of order types. Here are some common ones:

| Order Type | Description | Required Parameters |
|------------|-------------|---------------------|
| MKT | Market Order | conid, side, quantity |
| LMT | Limit Order | conid, side, quantity, price |
| STP | Stop Order | conid, side, quantity, auxPrice |
| STOP_LIMIT | Stop Limit Order | conid, side, quantity, price, auxPrice |
| TRAIL | Trailing Stop | conid, side, quantity, auxPrice (trail amount) |

## Time in Force Options

| TIF | Description |
|-----|-------------|
| DAY | Valid for the day |
| GTC | Good Till Canceled |
| IOC | Immediate or Cancel |
| FOK | Fill or Kill |

## Error Handling

All trading operations should include proper error handling:

```elixir
case IbkrApi.ClientPortal.Order.place_order(order_params) do
  {:ok, response} ->
    IO.puts("Order placed successfully: #{response.order_id}")
    
  {:error, %ErrorMessage{code: code, message: message}} ->
    IO.puts("Error placing order: #{message}")
    
    # Handle specific error codes
    case code do
      "10001" -> IO.puts("Insufficient funds")
      "10020" -> IO.puts("Contract not found")
      _ -> IO.puts("Unknown error")
    end
end
```

## Best Practices

1. **Validate contract information** before placing orders
2. **Start with small orders** when testing new strategies
3. **Implement proper error handling** for all trading operations
4. **Check order status** after placement to ensure it was accepted
5. **Use paper trading accounts** for testing and development
6. **Respect API rate limits** to avoid being temporarily blocked

## Related Resources

- [Getting Started](../tutorials/getting_started.html)
- [Authentication](../tutorials/authentication.html)
- [Account Management](account_management.html)
- [API Reference](../reference/api_reference.html)
