# IBKR Backtesting Framework

A comprehensive backtesting framework for the IBKR API Elixir library. Test your trading strategies against historical market data with detailed performance analytics.

## Overview

The backtesting framework consists of several key modules:

- **`Backtester.Bar`** - Historical market data structure
- **`Backtester.Portfolio`** - Portfolio management and P&L tracking
- **`Backtester.Strategy`** - Behavior for implementing trading strategies
- **`Backtester.Engine`** - Backtesting execution engine
- **`Backtester.Example`** - Usage examples and utilities

## Quick Start

### 1. Basic Backtest Example

```elixir
# Run a simple moving average strategy on Apple stock
{:ok, result} = Backtester.Example.run_backtest("AAPL", "3mo", "1day")

# Print detailed report
Backtester.Example.print_report(result)
```

### 2. Sample Backtest (No API Required)

```elixir
# Test with synthetic data
result = Backtester.Example.run_sample_backtest(
  strategy: Backtester.Strategies.MA,
  strategy_opts: [window: 20]
)

Backtester.Example.print_report(result)
```

## Detailed Usage

### Fetching Historical Data

```elixir
# Get historical data from IBKR API
alias IbkrApi.ClientPortal.MarketData

{:ok, bars} = MarketData.get_historical_data("265598", "1mo", "1day")

# Convert to backtester format
backtest_bars = Enum.map(bars, &Backtester.Bar.from_ibkr/1)
```

### Running a Backtest

```elixir
alias Backtester.{Engine, Strategies}

# Basic backtest
result = Engine.run(backtest_bars, Strategies.MA, 
  starting_cash: 50_000.0,
  strategy_opts: [window: 10]
)

# Detailed backtest with bar-by-bar tracking
detailed_result = Engine.run_detailed(backtest_bars, Strategies.MA)
```

### Creating Custom Strategies

```elixir
defmodule MyStrategy do
  use Backtester.Strategy

  def init(opts) do
    %{
      short_window: Keyword.get(opts, :short_window, 5),
      long_window: Keyword.get(opts, :long_window, 20)
    }
  end

  def signal(current_bar, previous_bars, state) do
    short_ma = calculate_ma(previous_bars, state.short_window)
    long_ma = calculate_ma(previous_bars, state.long_window)
    
    cond do
      short_ma > long_ma -> {:buy, state}
      short_ma < long_ma -> {:sell, state}
      true -> {:hold, state}
    end
  end

  defp calculate_ma(bars, window) do
    bars
    |> Enum.take(window)
    |> Enum.map(& &1.close)
    |> Enum.sum()
    |> Kernel./(window)
  end
end
```

## API Reference

### Backtester.Engine

#### `run/3`

Runs a basic backtest.

**Parameters:**
- `bars` - List of `Backtester.Bar` structs (chronologically ordered)
- `strategy_module` - Module implementing `Backtester.Strategy`
- `opts` - Options:
  - `:starting_cash` - Initial portfolio value (default: 100,000.0)
  - `:strategy_opts` - Options passed to strategy

**Returns:**
```elixir
%{
  portfolio: %Backtester.Portfolio{},
  performance: %{
    total_value: 105_250.0,
    total_return: 5_250.0,
    return_percent: 5.25,
    realized_pnl: 2_100.0,
    unrealized_pnl: 150.0,
    total_trades: 8
  },
  trade_history: [...],
  bars_processed: 100
}
```

#### `run_detailed/3`

Runs a detailed backtest with bar-by-bar portfolio tracking.

**Additional Returns:**
- `portfolio_values` - Array of portfolio values at each bar

#### `calculate_metrics/1`

Calculates extended performance metrics.

**Additional Metrics:**
- `win_rate` - Percentage of profitable trades
- `sharpe_ratio` - Risk-adjusted return measure
- `max_drawdown` - Maximum peak-to-trough decline
- `volatility` - Standard deviation of returns

### Backtester.Portfolio

Portfolio management with buy/sell/hold operations.

```elixir
# Create new portfolio
portfolio = Backtester.Portfolio.new(100_000.0)

# Execute trades
portfolio = Backtester.Portfolio.buy(portfolio, 150.0)
portfolio = Backtester.Portfolio.sell(portfolio, 160.0)

# Get performance stats
stats = Backtester.Portfolio.performance_stats(portfolio, current_price)
```

### Backtester.Strategy

Behavior for implementing trading strategies.

**Required Callback:**
```elixir
@callback signal(
  current_bar :: Backtester.Bar.t(),
  previous_bars :: [Backtester.Bar.t()],
  state :: map()
) :: {:buy | :sell | :hold, map()}
```

**Optional Callback:**
```elixir
@callback init(opts :: keyword()) :: map()
```

## Built-in Strategies

### Moving Average Strategy (`Backtester.Strategies.MA`)

Simple moving average crossover strategy.

**Options:**
- `:window` - Moving average period (default: 5)

**Logic:**
- Buy when price > moving average
- Sell when price < moving average
- Hold when price equals moving average

```elixir
# Use with custom window
Engine.run(bars, Backtester.Strategies.MA, 
  strategy_opts: [window: 20]
)
```

## Performance Metrics

### Basic Metrics
- **Total Return** - Absolute profit/loss
- **Return Percentage** - Percentage gain/loss
- **Realized P&L** - Profit from completed trades
- **Unrealized P&L** - Profit from open positions

### Advanced Metrics
- **Win Rate** - Percentage of profitable trades
- **Sharpe Ratio** - Risk-adjusted return (return/volatility)
- **Maximum Drawdown** - Largest peak-to-trough decline
- **Volatility** - Standard deviation of returns

## Examples

### Compare Multiple Strategies

```elixir
strategies = [
  Backtester.Strategies.MA
  # Add more strategies here
]

{:ok, comparison} = Backtester.Example.compare_strategies(
  "AAPL", "6mo", "1day", strategies
)

# Print comparison results
Enum.each(comparison.summary, fn strategy_result ->
  IO.puts("#{strategy_result.strategy}: #{strategy_result.return_percent}%")
end)
```

### Custom Analysis

```elixir
# Run detailed backtest
{:ok, result} = Backtester.Example.run_backtest("MSFT", "1y", "1day")

# Extract portfolio values for plotting
portfolio_values = result.portfolio_values
timestamps = Enum.map(portfolio_values, & &1.timestamp)
values = Enum.map(portfolio_values, & &1.portfolio_value)

# Calculate custom metrics
extended_metrics = Backtester.Engine.calculate_metrics(result)
IO.inspect(extended_metrics)
```

## Integration with IBKR API

The backtesting framework integrates seamlessly with the IBKR API:

1. **Contract Search** - Use `IbkrApi.ClientPortal.Contract.search_contracts/2`
2. **Historical Data** - Use `IbkrApi.ClientPortal.MarketData.get_historical_data/4`
3. **Data Conversion** - Use `Backtester.Bar.from_historical_bar/1`

### Complete Workflow

```elixir
# 1. Search for contract
{:ok, contracts} = IbkrApi.ClientPortal.Contract.search_contracts("AAPL")
contract_id = List.first(contracts).conid

# 2. Fetch historical data
{:ok, historical_bars} = IbkrApi.ClientPortal.MarketData.get_historical_data(
  to_string(contract_id), "3mo", "1day"
)

# 3. Convert to backtest format
backtest_bars = Enum.map(historical_bars, &Backtester.Bar.from_ibkr/1)

# 4. Run backtest
result = Backtester.Engine.run_detailed(backtest_bars, Backtester.Strategies.MA)

# 5. Analyze results
Backtester.Example.print_report(Map.put(result, :symbol, "AAPL"))
```

## Best Practices

1. **Data Quality** - Ensure historical data is clean and properly ordered
2. **Strategy Validation** - Test strategies on multiple time periods and symbols
3. **Risk Management** - Consider transaction costs and slippage in real trading
4. **Overfitting** - Avoid over-optimizing strategies on historical data
5. **Forward Testing** - Validate strategies on out-of-sample data

## Limitations

- **Simple Portfolio Model** - Currently supports single-asset, long-only strategies
- **No Transaction Costs** - Backtests don't include commissions or slippage
- **Perfect Execution** - Assumes all trades execute at exact bar close prices
- **No Risk Management** - No built-in stop-loss or position sizing rules

## Future Enhancements

- Multi-asset portfolio support
- Short selling capabilities
- Transaction cost modeling
- Advanced order types
- Risk management features
- Performance attribution analysis
