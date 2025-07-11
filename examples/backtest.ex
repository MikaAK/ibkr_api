defmodule Examples.Backtest do
  @moduledoc """
  Example usage of the IBKR backtesting framework.

  This module demonstrates how to fetch historical data from IBKR
  and run backtests with different strategies.
  """

  alias IbkrApi.ClientPortal.{MarketData, Contract}
  alias IbkrApi.Backtester.{Engine, Bar, Strategies}

  @doc """
  Complete example: Search for a contract, fetch historical data, and run backtest.

  ## Parameters
  - `symbol`: Stock symbol to backtest (e.g., "AAPL")
  - `period`: Historical data period (e.g., "1mo", "3mo", "1y")
  - `bar_size`: Bar size (e.g., "1day", "1hour", "30min")
  - `strategy_module`: Strategy module to use (default: MA strategy)
  - `opts`: Additional options

  ## Examples
      # Run a simple moving average backtest on Apple stock
      iex> IbkrApi.Backtester.Example.run_backtest("AAPL", "3mo", "1day")
      {:ok, %{performance: %{return_percent: 12.5, ...}, ...}}

      # Run with custom strategy options
      iex> IbkrApi.Backtester.Example.run_backtest("MSFT", "6mo", "1hour",
      ...>   IbkrApi.Backtester.Strategies.MA, strategy_opts: [window: 20])
      {:ok, %{...}}
  """
  @spec run_backtest(String.t(), String.t(), String.t(), module(), keyword()) ::
    {:ok, map()} | {:error, any()}
  def run_backtest(symbol, period, bar_size, strategy_module \\ Strategies.MA, opts \\ []) do
    with {:ok, contract_id} <- find_contract_id(symbol),
         {:ok, historical_bars} <- fetch_historical_data(contract_id, period, bar_size),
         {:ok, backtest_bars} <- convert_to_backtest_bars(historical_bars) do

      # Run the backtest
      result = Engine.run_detailed(backtest_bars, strategy_module, opts)

      # Add some additional context
      enhanced_result = Map.merge(result, %{
        symbol: symbol,
        period: period,
        bar_size: bar_size,
        contract_id: contract_id
      })

      {:ok, enhanced_result}
    end
  end

  @doc """
  Quick backtest example with sample data (for testing without API calls).

  Generates synthetic price data and runs a backtest.
  """
  @spec run_sample_backtest(keyword()) :: map()
  def run_sample_backtest(opts \\ []) do
    # Generate sample bars (trending upward with some volatility)
    sample_bars = generate_sample_bars(100, 100.0)

    strategy_module = Keyword.get(opts, :strategy, Strategies.MA)
    strategy_opts = Keyword.get(opts, :strategy_opts, [window: 10])

    Engine.run_detailed(sample_bars, strategy_module, strategy_opts: strategy_opts)
  end

  @doc """
  Demonstrates multiple strategy comparison.

  Runs the same historical data through different strategies and compares results.
  """
  @spec compare_strategies(String.t(), String.t(), String.t(), [module()], keyword()) ::
    {:ok, map()} | {:error, any()}
  def compare_strategies(symbol, period, bar_size, strategies \\ [Strategies.MA], opts \\ []) do
    with {:ok, contract_id} <- find_contract_id(symbol),
         {:ok, historical_bars} <- fetch_historical_data(contract_id, period, bar_size),
         {:ok, backtest_bars} <- convert_to_backtest_bars(historical_bars) do

      # Run backtest for each strategy
      results =
        Enum.map(strategies, fn strategy ->
          strategy_opts = Keyword.get(opts, :strategy_opts, [])
          result = Engine.run(backtest_bars, strategy, strategy_opts: strategy_opts)

          {strategy, result}
        end)
        |> Map.new()

      comparison = %{
        symbol: symbol,
        period: period,
        bar_size: bar_size,
        strategies: results,
        summary: create_strategy_summary(results)
      }

      {:ok, comparison}
    end
  end

  @doc """
  Print a formatted backtest report.
  """
  @spec print_report(map()) :: :ok
  def print_report(%{performance: perf, symbol: symbol} = result) do
    IO.puts("\n" <> String.duplicate("=", 50))
    IO.puts("BACKTEST REPORT")
    IO.puts(String.duplicate("=", 50))
    IO.puts("Symbol: #{symbol}")
    IO.puts("Period: #{Map.get(result, :period, "N/A")}")
    IO.puts("Strategy: #{inspect(Map.get(result, :strategy, "N/A"))}")
    IO.puts("")
    IO.puts("PERFORMANCE:")
    IO.puts("Starting Value: $#{:erlang.float_to_binary(Map.get(result, :starting_cash, 0.0), decimals: 2)}")
    IO.puts("Final Value: $#{:erlang.float_to_binary(perf.total_value, decimals: 2)}")
    IO.puts("Total Return: $#{:erlang.float_to_binary(perf.total_return, decimals: 2)}")
    IO.puts("Return %: #{:erlang.float_to_binary(perf.return_percent, decimals: 2)}%")
    IO.puts("Realized P&L: $#{:erlang.float_to_binary(perf.realized_pnl, decimals: 2)}")
    IO.puts("Unrealized P&L: $#{:erlang.float_to_binary(perf.unrealized_pnl, decimals: 2)}")
    IO.puts("Total Trades: #{perf.total_trades}")

    # Print extended metrics if available
    extended_metrics = Engine.calculate_metrics(result)
    if Map.has_key?(extended_metrics, :win_rate) do
      IO.puts("")
      IO.puts("TRADE METRICS:")
      IO.puts("Win Rate: #{:erlang.float_to_binary(extended_metrics.win_rate, decimals: 1)}%")
      IO.puts("Avg Trade Return: $#{:erlang.float_to_binary(extended_metrics.avg_trade_return, decimals: 2)}")
      IO.puts("Completed Trades: #{Map.get(extended_metrics, :completed_trades, 0)}")
    end

    if Map.has_key?(extended_metrics, :sharpe_ratio) do
      IO.puts("")
      IO.puts("RISK METRICS:")
      IO.puts("Sharpe Ratio: #{:erlang.float_to_binary(extended_metrics.sharpe_ratio, decimals: 2)}")
      IO.puts("Max Drawdown: #{:erlang.float_to_binary(extended_metrics.max_drawdown, decimals: 2)}%")
      IO.puts("Volatility: #{:erlang.float_to_binary(extended_metrics.volatility * 100, decimals: 2)}%")
    end

    IO.puts(String.duplicate("=", 50))
    :ok
  end

  # Private helper functions

  defp find_contract_id(symbol) do
    case Contract.search_contracts(symbol, sec_type: "STK") do
      {:ok, [_ | _] = contracts} ->
        # Take the first matching contract
        contract = List.first(contracts)
        {:ok, to_string(contract.conid)}

      {:ok, []} ->
        {:error, "No contracts found for symbol: #{symbol}"}

      {:error, reason} ->
        {:error, "Contract search failed: #{inspect(reason)}"}
    end
  end

  defp fetch_historical_data(contract_id, period, bar_size) do
    case MarketData.get_historical_data(contract_id, period, bar_size) do
      {:ok, [_ | _] = bars} ->
        {:ok, bars}

      {:ok, []} ->
        {:error, "No historical data returned"}

      {:error, reason} ->
        {:error, "Historical data fetch failed: #{inspect(reason)}"}
    end
  end

  defp convert_to_backtest_bars(historical_bars) do
    try do
      backtest_bars = Enum.map(historical_bars, &Bar.from_ibkr/1)
      {:ok, backtest_bars}
    rescue
      e -> {:error, "Bar conversion failed: #{inspect(e)}"}
    end
  end

  defp generate_sample_bars(count, starting_price) do
    # Generate bars with random walk + slight upward trend
    {bars, _} =
      Enum.reduce(1..count, {[], starting_price}, fn i, {bars, price} ->
        # Random price movement with slight upward bias
        change_pct = (:rand.uniform() - 0.48) * 0.05  # -2.4% to +2.6% per bar
        new_price = price * (1 + change_pct)

        # Create OHLC data
        high = new_price * (1 + :rand.uniform() * 0.02)  # Up to 2% higher
        low = new_price * (1 - :rand.uniform() * 0.02)   # Up to 2% lower
        open = price
        close = new_price
        volume = 1000 + :rand.uniform(9000)  # 1K to 10K volume

        timestamp = DateTime.add(DateTime.utc_now(), -count + i, :day)

        bar = %Bar{
          timestamp: timestamp,
          open: open,
          high: high,
          low: low,
          close: close,
          volume: volume
        }

        {[bar | bars], new_price}
      end)

    Enum.reverse(bars)
  end

  defp create_strategy_summary(results) do
    Enum.map(results, fn {strategy, result} ->
      perf = result.performance

      %{
        strategy: strategy,
        return_percent: perf.return_percent,
        total_return: perf.total_return,
        total_trades: perf.total_trades,
        final_value: perf.total_value
      }
    end)
    |> Enum.sort_by(& &1.return_percent, :desc)
  end
end
