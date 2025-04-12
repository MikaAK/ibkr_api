# Account Management

This guide covers common account management tasks using the IbkrApi library.

## Listing Accounts

To retrieve all accounts associated with your Interactive Brokers login:

```elixir
{:ok, accounts} = IbkrApi.ClientPortal.Account.list_accounts()

# Process the accounts
accounts |> Enum.each(fn account ->
  IO.puts("Account ID: #{account.account_id}")
  IO.puts("Account Title: #{account.account_title}")
  IO.puts("Account Type: #{account.type}")
  IO.puts("---")
end)
```

## Retrieving Account Details

### Account Summary

To get a comprehensive summary of an account:

```elixir
account_id = "U1234567"  # Replace with your actual account ID
{:ok, summary} = IbkrApi.ClientPortal.Account.account_summary(account_id)

# Access common summary information
IO.puts("Available Funds: #{summary.available_funds}")
IO.puts("Buying Power: #{summary.buying_power}")
IO.puts("Equity with Loan Value: #{summary.equity_with_loan_value}")
IO.puts("Excess Liquidity: #{summary.excess_liquidity}")
```

### Account Ledger

To retrieve the account ledger information:

```elixir
{:ok, ledger} = IbkrApi.ClientPortal.Account.account_ledger(account_id)

# Access ledger information for the base currency
base_currency = ledger.BASE
IO.puts("Cash Balance: #{base_currency.cashbalance}")
IO.puts("Net Liquidation Value: #{base_currency.netliquidationvalue}")
IO.puts("Realized P&L: #{base_currency.realizedpnl}")
IO.puts("Unrealized P&L: #{base_currency.unrealizedpnl}")
```

## Working with Sub-Accounts

If you have a master account with sub-accounts:

### Listing Sub-Accounts

```elixir
{:ok, sub_accounts} = IbkrApi.ClientPortal.Account.list_sub_accounts()

# Process sub-accounts
sub_accounts |> Enum.each(fn sub_account ->
  IO.puts("Sub-Account ID: #{sub_account.account_id}")
  IO.puts("Sub-Account Title: #{sub_account.account_title}")
  IO.puts("---")
end)
```

### Listing Large Sub-Accounts with Pagination

For accounts with many sub-accounts:

```elixir
# Get the first page
{:ok, large_sub_accounts} = IbkrApi.ClientPortal.Account.list_large_sub_accounts("0")

# Display metadata
IO.puts("Total Sub-Accounts: #{large_sub_accounts.metadata.total}")
IO.puts("Page Size: #{large_sub_accounts.metadata.page_size}")

# Process sub-accounts on this page
large_sub_accounts.subaccounts |> Enum.each(fn sub_account ->
  IO.puts("Sub-Account ID: #{sub_account.account_id}")
end)

# Get the next page if needed
if large_sub_accounts.metadata.total > large_sub_accounts.metadata.page_size do
  {:ok, next_page} = IbkrApi.ClientPortal.Account.list_large_sub_accounts("1")
  # Process next page...
end
```

## Switching Between Accounts

If you need to switch the active account for subsequent API calls:

```elixir
target_account_id = "U7654321"  # Replace with the account ID you want to switch to
{:ok, switch_response} = IbkrApi.ClientPortal.Account.switch_account(target_account_id)

if switch_response.set do
  IO.puts("Successfully switched to account #{switch_response.acctId}")
else
  IO.puts("Failed to switch account")
end
```

## Retrieving Profit and Loss Information

To get P&L information for your account:

```elixir
{:ok, pnl_response} = IbkrApi.ClientPortal.Account.get_pnl()

# Process P&L data
account_ids = Map.keys(pnl_response.acctId)
account_ids |> Enum.each(fn account_id ->
  account_pnl = pnl_response.acctId[account_id]
  IO.puts("Account: #{account_id}")
  IO.puts("P&L data: #{inspect(account_pnl)}")
  IO.puts("---")
end)
```

## Error Handling

All API functions return `{:ok, result}` on success and `{:error, reason}` on failure. It's good practice to handle errors appropriately:

```elixir
case IbkrApi.ClientPortal.Account.account_summary(account_id) do
  {:ok, summary} ->
    # Process the summary...
    IO.puts("Available Funds: #{summary.available_funds}")
    
  {:error, %ErrorMessage{code: code, message: message}} ->
    IO.puts("Error #{code}: #{message}")
    
    # Handle specific error codes
    case code do
      "1015" -> IO.puts("Account not found or not authorized")
      "1021" -> IO.puts("Session expired, please reauthenticate")
      _ -> IO.puts("Unknown error")
    end
end
```

## Best Practices

1. **Cache account information** when appropriate to reduce API calls
2. **Check authentication status** before making account-related calls
3. **Handle pagination** properly when dealing with large datasets
4. **Implement proper error handling** for all API calls
5. **Respect API rate limits** to avoid being temporarily blocked

## Related Resources

- [Getting Started](../tutorials/getting_started.html)
- [Authentication](../tutorials/authentication.html)
- [Trading](trading.html)
- [API Reference](../reference/api_reference.html)
