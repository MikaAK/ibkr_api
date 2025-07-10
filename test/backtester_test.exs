defmodule BacktesterTest do
  @moduledoc """
  Integration tests for the IBKR backtesting framework.
  
  These tests demonstrate the complete functionality of the backtesting system
  using synthetic data to avoid API dependencies.
  """

  use ExUnit.Case
  doctest IbkrApi.Backtester.Bar
  doctest IbkrApi.Backtester.Portfolio
  doctest IbkrApi.Backtester.Engine

  alias IbkrApi.Backtester.{Bar, Portfolio, Engine, Strategies}

  describe "Bar module" do
    test "creates bar from IBKR API data" do
      ibkr_data = %{
        "t" => 1_640_995_200_000,  # 2022-01-01 00:00:00 UTC
        "o" => 100.0,
        "h" => 105.0,
        "l" => 98.0,
        "c" => 103.0,
        "v" => 1_000_000
      }

      bar = Bar.from_ibkr(ibkr_data)

      assert bar.open == 100.0
      assert bar.high == 105.0
      assert bar.low == 98.0
      assert bar.close == 103.0
      assert bar.volume == 1_000_000
      assert %DateTime{} = bar.timestamp
    end

    test "calculates typical price" do
      bar = %Bar{high: 105.0, low: 95.0, close: 100.0}
      assert Bar.typical_price(bar) == 100.0
    end

    test "identifies bullish and bearish bars" do
      bullish_bar = %Bar{open: 100.0, close: 105.0}
      bearish_bar = %Bar{open: 105.0, close: 100.0}

      assert Bar.bullish?(bullish_bar)
      refute Bar.bearish?(bullish_bar)
      
      assert Bar.bearish?(bearish_bar)
      refute Bar.bullish?(bearish_bar)
    end
  end

  describe "Portfolio module" do
    test "creates new portfolio with starting cash" do
      portfolio = Portfolio.new(50_000.0)
      
      assert portfolio.cash == 50_000.0
      assert portfolio.position == 0
      assert portfolio.entry_price == nil
      assert portfolio.trades == []
    end

    test "executes buy order when no position held" do
      portfolio = Portfolio.new(10_000.0)
      timestamp = DateTime.utc_now()
      
      updated_portfolio = Portfolio.buy(portfolio, 100.0, timestamp)
      
      assert updated_portfolio.cash == 9_900.0  # 10,000 - 100
      assert updated_portfolio.position == 1
      assert updated_portfolio.entry_price == 100.0
      assert length(updated_portfolio.trades) == 1
    end

    test "ignores buy order when position already held" do
      portfolio = %Portfolio{
        cash: 9_900.0,
        position: 1,
        entry_price: 100.0,
        trades: [{:buy, 100.0, DateTime.utc_now()}]
      }
      
      result = Portfolio.buy(portfolio, 110.0)
      assert result == portfolio  # No change
    end

    test "executes sell order when position held" do
      timestamp = DateTime.utc_now()
      portfolio = %Portfolio{
        cash: 9_900.0,
        position: 1,
        entry_price: 100.0,
        trades: [{:buy, 100.0, timestamp}]
      }
      
      updated_portfolio = Portfolio.sell(portfolio, 110.0, timestamp)
      
      assert updated_portfolio.cash == 10_010.0  # 9,900 + 110
      assert updated_portfolio.position == 0
      assert updated_portfolio.entry_price == nil
      assert length(updated_portfolio.trades) == 2
    end

    test "calculates portfolio performance" do
      portfolio = %Portfolio{
        cash: 9_900.0,
        position: 1,
        entry_price: 100.0,
        trades: [{:buy, 100.0, DateTime.utc_now()}]
      }
      
      current_price = 110.0
      starting_cash = 10_000.0
      
      performance = Portfolio.performance_stats(portfolio, current_price, starting_cash)
      
      assert performance.total_value == 10_010.0  # 9,900 cash + 110 position value
      assert performance.total_return == 10.0     # 10,010 - 10,000
      assert performance.return_percent == 0.1    # 10/10,000
      assert performance.unrealized_pnl == 10.0   # 110 - 100
      assert performance.realized_pnl == 0.0
    end
  end

  describe "Moving Average Strategy" do
    test "generates correct signals" do
      # Create bars with upward trend
      bars = [
        %Bar{close: 100.0, timestamp: DateTime.utc_now()},
        %Bar{close: 101.0, timestamp: DateTime.utc_now()},
        %Bar{close: 102.0, timestamp: DateTime.utc_now()},
        %Bar{close: 103.0, timestamp: DateTime.utc_now()},
        %Bar{close: 104.0, timestamp: DateTime.utc_now()},
        %Bar{close: 105.0, timestamp: DateTime.utc_now()}  # Current bar
      ]
      
      current_bar = List.last(bars)
      previous_bars = Enum.reverse(Enum.drop(bars, -1))
      
      state = Strategies.MA.init(window: 3)
      {signal, _new_state} = Strategies.MA.signal(current_bar, previous_bars, state)
      
      # With window=3, MA of [104, 103, 102] = 103, current price 105 > 103, so buy
      assert signal == :buy
    end

    test "handles insufficient data gracefully" do
      current_bar = %Bar{close: 100.0, timestamp: DateTime.utc_now()}
      previous_bars = []  # No previous data
      
      state = Strategies.MA.init(window: 5)
      {signal, _new_state} = Strategies.MA.signal(current_bar, previous_bars, state)
      
      assert signal == :hold
    end
  end

  describe "Backtesting Engine" do
    test "runs complete backtest with sample data" do
      bars = create_sample_bars(20, 100.0)
      
      result = Engine.run(bars, Strategies.MA, 
        starting_cash: 10_000.0,
        strategy_opts: [window: 3]
      )
      
      assert result.bars_processed == 20
      assert result.starting_cash == 10_000.0
      assert result.strategy == Strategies.MA
      assert %Portfolio{} = result.portfolio
      assert is_map(result.performance)
      assert is_list(result.trade_history)
    end

    test "runs detailed backtest with portfolio tracking" do
      bars = create_sample_bars(10, 100.0)
      
      result = Engine.run_detailed(bars, Strategies.MA,
        starting_cash: 5_000.0,
        strategy_opts: [window: 2]
      )
      
      assert Map.has_key?(result, :portfolio_values)
      assert length(result.portfolio_values) == 10
      
      # Check portfolio value structure
      first_value = List.first(result.portfolio_values)
      assert Map.has_key?(first_value, :timestamp)
      assert Map.has_key?(first_value, :portfolio_value)
      assert Map.has_key?(first_value, :bar_index)
    end

    test "calculates extended performance metrics" do
      bars = create_trending_bars(50, 100.0, 0.01)  # 1% daily growth
      
      result = Engine.run_detailed(bars, Strategies.MA,
        starting_cash: 10_000.0,
        strategy_opts: [window: 5]
      )
      
      metrics = Engine.calculate_metrics(result)
      
      assert Map.has_key?(metrics, :win_rate)
      assert Map.has_key?(metrics, :total_trades)
      assert Map.has_key?(metrics, :sharpe_ratio)
      assert Map.has_key?(metrics, :max_drawdown)
      assert Map.has_key?(metrics, :volatility)
      
      # Basic sanity checks
      assert metrics.win_rate >= 0.0
      assert metrics.win_rate <= 100.0
      assert metrics.total_trades >= 0
    end

    test "handles empty bar list gracefully" do
      result = Engine.run([], Strategies.MA)
      
      assert result.bars_processed == 0
      assert result.portfolio.cash == 100_000.0  # Default starting cash
      assert result.trade_history == []
    end
  end

  describe "Integration with sample data" do
    test "complete workflow with synthetic market data" do
      # Create realistic market scenario: bull market with volatility
      bars = create_realistic_market_data(100)
      
      # Run backtest
      result = Engine.run_detailed(bars, Strategies.MA,
        starting_cash: 25_000.0,
        strategy_opts: [window: 10]
      )
      
      # Validate results
      assert result.bars_processed == 100
      assert result.starting_cash == 25_000.0
      
      # Should have some trading activity in 100 bars
      assert length(result.trade_history) > 0
      
      # Portfolio value should be tracked for each bar
      assert length(result.portfolio_values) == 100
      
      # Calculate and validate metrics
      metrics = Engine.calculate_metrics(result)
      
      # Print results for manual inspection
      IO.puts("\n=== INTEGRATION TEST RESULTS ===")
      IO.puts("Bars processed: #{result.bars_processed}")
      IO.puts("Total trades: #{length(result.trade_history)}")
      IO.puts("Final portfolio value: $#{:erlang.float_to_binary(result.performance.total_value, decimals: 2)}")
      IO.puts("Total return: #{:erlang.float_to_binary(result.performance.return_percent, decimals: 2)}%")
      IO.puts("Win rate: #{:erlang.float_to_binary(metrics.win_rate, decimals: 1)}%")
      IO.puts("Sharpe ratio: #{:erlang.float_to_binary(metrics.sharpe_ratio, decimals: 2)}")
      IO.puts("Max drawdown: #{:erlang.float_to_binary(metrics.max_drawdown, decimals: 2)}%")
      
      # Basic validation - should have reasonable results
      assert result.performance.total_value > 0
      assert metrics.total_trades >= 0
    end
  end

  # Helper functions for creating test data

  defp create_sample_bars(count, starting_price) do
    Enum.map(1..count, fn i ->
      price = starting_price + i * 0.5  # Gradual upward trend
      
      %Bar{
        timestamp: DateTime.add(DateTime.utc_now(), -count + i, :day),
        open: price - 0.25,
        high: price + 0.5,
        low: price - 0.5,
        close: price,
        volume: 1000 + :rand.uniform(500)
      }
    end)
  end

  defp create_trending_bars(count, starting_price, daily_return) do
    {bars, _} = 
      Enum.reduce(1..count, {[], starting_price}, fn i, {bars, price} ->
        new_price = price * (1 + daily_return + (:rand.uniform() - 0.5) * 0.02)
        
        bar = %Bar{
          timestamp: DateTime.add(DateTime.utc_now(), -count + i, :day),
          open: price,
          high: max(price, new_price) * (1 + :rand.uniform() * 0.01),
          low: min(price, new_price) * (1 - :rand.uniform() * 0.01),
          close: new_price,
          volume: 1000 + :rand.uniform(2000)
        }
        
        {[bar | bars], new_price}
      end)
    
    Enum.reverse(bars)
  end

  defp create_realistic_market_data(count) do
    # Create market data with different phases: sideways, bull, bear, recovery
    phases = [
      {20, 0.0},    # Sideways market
      {30, 0.015},  # Bull market (+1.5% daily)
      {25, -0.01},  # Bear market (-1% daily)
      {25, 0.008}   # Recovery (+0.8% daily)
    ]
    
    {bars, _} = 
      Enum.reduce(phases, {[], 100.0}, fn {phase_length, daily_return}, {acc_bars, start_price} ->
        phase_bars = create_trending_bars(phase_length, start_price, daily_return)
        final_price = List.last(phase_bars).close
        
        {acc_bars ++ phase_bars, final_price}
      end)
    
    Enum.take(bars, count)
  end
end
