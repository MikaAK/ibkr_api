defmodule IbkrApi.Backtester.Strategies.MA do
  @moduledoc """
  Simple Moving Average crossover strategy.
  
  Generates buy signals when price is above the moving average
  and sell signals when price is below the moving average.
  """

  use IbkrApi.Backtester.Strategy

  @default_window 5

  @doc """
  Initialize the strategy with configuration options.
  
  ## Options
  - `:window` - Moving average window size (default: 5)
  
  ## Examples
      iex> IbkrApi.Backtester.Strategies.MA.init(window: 10)
      %{window: 10}
  """
  def init(opts \\ []) do
    window = Keyword.get(opts, :window, @default_window)
    %{window: window}
  end

  @doc """
  Generates trading signals based on moving average crossover.
  
  ## Logic
  - Buy when current price > moving average
  - Sell when current price < moving average  
  - Hold when price equals moving average or insufficient data
  """
  def signal(current_bar, previous_bars, state) do
    window = Map.get(state, :window, @default_window)
    
    # Create window of bars including current bar
    all_bars = [current_bar | Enum.take(previous_bars, window - 1)]
    
    if length(all_bars) < window do
      # Not enough data for moving average
      {:hold, state}
    else
      moving_average = calculate_sma(all_bars, window)
      
      cond do
        current_bar.close > moving_average -> {:buy, state}
        current_bar.close < moving_average -> {:sell, state}
        true -> {:hold, state}
      end
    end
  end

  @doc """
  Calculates Simple Moving Average for the given bars.
  
  ## Parameters
  - `bars`: List of bars (most recent first)
  - `window`: Number of periods to average
  
  ## Examples
      iex> bars = [%{close: 100}, %{close: 102}, %{close: 98}]
      iex> IbkrApi.Backtester.Strategies.MA.calculate_sma(bars, 3)
      100.0
  """
  @spec calculate_sma([IbkrApi.Backtester.Bar.t()], pos_integer()) :: float()
  def calculate_sma(bars, window) when length(bars) >= window do
    bars
    |> Enum.take(window)
    |> Enum.map(& &1.close)
    |> Enum.sum()
    |> Kernel./(window)
  end

  def calculate_sma(_bars, _window), do: 0.0
end
