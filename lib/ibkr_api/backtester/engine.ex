defmodule IbkrApi.Backtester.Engine do
  @moduledoc """
  Backtesting engine that runs strategies against historical data.
  
  The engine processes historical bars sequentially, calling the strategy
  for each bar and executing the resulting trades on the portfolio.
  """

  alias IbkrApi.Backtester.{Bar, Portfolio}

  @doc """
  Runs a backtest with the given bars and strategy.
  
  ## Parameters
  - `bars`: List of historical bars (chronologically ordered, oldest first)
  - `strategy_module`: Module implementing the IbkrApi.Backtester.Strategy behaviour
  - `opts`: Optional configuration
    - `:starting_cash` - Initial portfolio cash (default: 100,000.0)
    - `:strategy_opts` - Options passed to strategy.init/1 (default: [])
  
  ## Returns
  A map containing:
  - `:portfolio` - Final portfolio state
  - `:performance` - Performance statistics
  - `:trade_history` - List of all executed trades
  - `:bars_processed` - Number of bars processed
  
  ## Examples
      iex> bars = [%IbkrApi.Backtester.Bar{close: 100.0, open: 99.0, high: 101.0, low: 98.0, volume: 1000, timestamp: DateTime.utc_now()}]
      iex> result = IbkrApi.Backtester.Engine.run(bars, IbkrApi.Backtester.Strategies.MA)
      iex> is_map(result)
      true
  """
  @spec run([Bar.t()], module(), keyword()) :: map()
  def run(bars, strategy_module, opts \\ []) do
    starting_cash = Keyword.get(opts, :starting_cash, 100_000.0)
    strategy_opts = Keyword.get(opts, :strategy_opts, [])
    
    # Initialize strategy and portfolio
    strategy_state = 
      if function_exported?(strategy_module, :init, 1) do
        strategy_module.init(strategy_opts)
      else
        %{}
      end
    
    initial_portfolio = Portfolio.new(starting_cash)
    
    # Process bars sequentially
    {final_portfolio, _final_state, trade_history} = 
      bars
      |> Enum.with_index()
      |> Enum.reduce({initial_portfolio, strategy_state, []}, fn {bar, index}, {portfolio, state, trades} ->
        # Get previous bars (most recent first)
        previous_bars = 
          bars
          |> Enum.take(index)
          |> Enum.reverse()
        
        # Get strategy signal
        {signal, updated_state} = strategy_module.signal(bar, previous_bars, state)
        
        # Execute trade based on signal
        {updated_portfolio, new_trades} = execute_signal(portfolio, signal, bar)
        
        {updated_portfolio, updated_state, new_trades ++ trades}
      end)
    
    # Calculate final performance
    final_price = List.last(bars).close
    performance = Portfolio.performance_stats(final_portfolio, final_price, starting_cash)
    
    %{
      portfolio: final_portfolio,
      performance: performance,
      trade_history: Enum.reverse(trade_history),
      bars_processed: length(bars),
      strategy: strategy_module,
      starting_cash: starting_cash
    }
  end

  @doc """
  Runs a backtest and returns detailed results with bar-by-bar portfolio values.
  
  This version tracks portfolio value at each bar for plotting and analysis.
  """
  @spec run_detailed([Bar.t()], module(), keyword()) :: map()
  def run_detailed(bars, strategy_module, opts \\ []) do
    starting_cash = Keyword.get(opts, :starting_cash, 100_000.0)
    strategy_opts = Keyword.get(opts, :strategy_opts, [])
    
    # Initialize strategy and portfolio
    strategy_state = 
      if function_exported?(strategy_module, :init, 1) do
        strategy_module.init(strategy_opts)
      else
        %{}
      end
    
    initial_portfolio = Portfolio.new(starting_cash)
    
    # Process bars and track portfolio values
    {final_portfolio, _final_state, trade_history, portfolio_values} = 
      bars
      |> Enum.with_index()
      |> Enum.reduce({initial_portfolio, strategy_state, [], []}, fn {bar, index}, {portfolio, state, trades, values} ->
        # Get previous bars (most recent first)
        previous_bars = 
          bars
          |> Enum.take(index)
          |> Enum.reverse()
        
        # Get strategy signal
        {signal, updated_state} = strategy_module.signal(bar, previous_bars, state)
        
        # Execute trade based on signal
        {updated_portfolio, new_trades} = execute_signal(portfolio, signal, bar)
        
        # Track portfolio value at this bar
        portfolio_value = Portfolio.total_value(updated_portfolio, bar.close)
        value_entry = %{
          timestamp: bar.timestamp,
          portfolio_value: portfolio_value,
          bar_index: index
        }
        
        {updated_portfolio, updated_state, new_trades ++ trades, [value_entry | values]}
      end)
    
    # Calculate final performance
    final_price = List.last(bars).close
    performance = Portfolio.performance_stats(final_portfolio, final_price, starting_cash)
    
    %{
      portfolio: final_portfolio,
      performance: performance,
      trade_history: Enum.reverse(trade_history),
      portfolio_values: Enum.reverse(portfolio_values),
      bars_processed: length(bars),
      strategy: strategy_module,
      starting_cash: starting_cash
    }
  end

  # Private helper to execute trading signals
  defp execute_signal(portfolio, signal, bar) do
    case signal do
      :buy ->
        updated_portfolio = Portfolio.buy(portfolio, bar.close, bar.timestamp)
        if updated_portfolio.position > portfolio.position do
          {updated_portfolio, [{:buy, bar.close, bar.timestamp, bar}]}
        else
          {portfolio, []}
        end
        
      :sell ->
        updated_portfolio = Portfolio.sell(portfolio, bar.close, bar.timestamp)
        if updated_portfolio.position < portfolio.position do
          {updated_portfolio, [{:sell, bar.close, bar.timestamp, bar}]}
        else
          {portfolio, []}
        end
        
      :hold ->
        {portfolio, []}
    end
  end

  @doc """
  Calculates key performance metrics for a backtest result.
  
  ## Parameters
  - `result`: Result map from run/3 or run_detailed/3
  
  ## Returns
  Extended performance metrics including:
  - Sharpe ratio (if portfolio_values available)
  - Maximum drawdown
  - Win rate
  - Average trade return
  """
  @spec calculate_metrics(map()) :: map()
  def calculate_metrics(%{performance: performance, trade_history: trades} = result) do
    base_metrics = performance
    
    # Calculate trade-based metrics
    trade_metrics = calculate_trade_metrics(trades)
    
    # Calculate time-series metrics if available
    time_series_metrics = 
      if Map.has_key?(result, :portfolio_values) do
        calculate_time_series_metrics(result.portfolio_values, result.starting_cash)
      else
        %{}
      end
    
    Map.merge(base_metrics, Map.merge(trade_metrics, time_series_metrics))
  end

  # Calculate metrics based on individual trades
  defp calculate_trade_metrics(trades) do
    if length(trades) < 2 do
      %{win_rate: 0.0, avg_trade_return: 0.0, total_trades: length(trades)}
    else
      # Group trades into buy/sell pairs
      trade_pairs = group_trade_pairs(trades)
      
      if length(trade_pairs) == 0 do
        %{win_rate: 0.0, avg_trade_return: 0.0, total_trades: length(trades)}
      else
        returns = Enum.map(trade_pairs, fn {buy_price, sell_price} -> sell_price - buy_price end)
        winning_trades = Enum.count(returns, &(&1 > 0))
        
        %{
          win_rate: (winning_trades / length(trade_pairs)) * 100.0,
          avg_trade_return: Enum.sum(returns) / length(returns),
          total_trades: length(trades),
          completed_trades: length(trade_pairs)
        }
      end
    end
  end

  # Group trades into buy/sell pairs
  defp group_trade_pairs(trades) do
    trades
    |> Enum.chunk_every(2)
    |> Enum.filter(&(length(&1) == 2))
    |> Enum.map(fn [{:buy, buy_price, _, _}, {:sell, sell_price, _, _}] -> {buy_price, sell_price} end)
  end

  # Calculate time-series based metrics
  defp calculate_time_series_metrics(portfolio_values, _starting_cash) do
    if length(portfolio_values) < 2 do
      %{}
    else
      values = Enum.map(portfolio_values, & &1.portfolio_value)
      returns = calculate_returns(values)
      
      max_drawdown = calculate_max_drawdown(values)
      sharpe_ratio = calculate_sharpe_ratio(returns)
      
      %{
        max_drawdown: max_drawdown,
        sharpe_ratio: sharpe_ratio,
        volatility: calculate_volatility(returns)
      }
    end
  end

  # Calculate period returns
  defp calculate_returns(values) do
    values
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(fn [prev, curr] -> (curr - prev) / prev end)
  end

  # Calculate maximum drawdown
  defp calculate_max_drawdown(values) do
    {_peak, max_dd} = 
      Enum.reduce(values, {0.0, 0.0}, fn value, {peak, max_drawdown} ->
        new_peak = max(peak, value)
        drawdown = (new_peak - value) / new_peak
        {new_peak, max(max_drawdown, drawdown)}
      end)
    
    max_dd * 100.0  # Return as percentage
  end

  # Calculate Sharpe ratio (assuming daily returns, risk-free rate = 0)
  defp calculate_sharpe_ratio(returns) do
    if length(returns) < 2 do
      0.0
    else
      mean_return = Enum.sum(returns) / length(returns)
      std_dev = calculate_volatility(returns)
      
      if std_dev == 0.0 do
        0.0
      else
        # Annualize assuming daily returns
        (mean_return * :math.sqrt(252)) / std_dev
      end
    end
  end

  # Calculate volatility (standard deviation of returns)
  defp calculate_volatility(returns) do
    if length(returns) < 2 do
      0.0
    else
      mean = Enum.sum(returns) / length(returns)
      variance = 
        returns
        |> Enum.map(&(:math.pow(&1 - mean, 2)))
        |> Enum.sum()
        |> Kernel./(length(returns) - 1)
      
      :math.sqrt(variance)
    end
  end
end
