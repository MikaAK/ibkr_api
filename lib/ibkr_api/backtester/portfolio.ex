defmodule IbkrApi.Backtester.Portfolio do
  @moduledoc """
  Portfolio management for backtesting.
  
  Tracks cash, positions, and trade history during backtesting simulations.
  Supports simple long-only strategies with buy/sell/hold operations.
  """

  defstruct cash: 100_000.0, position: 0, entry_price: nil, trades: []

  @type t :: %__MODULE__{
          cash: float(),
          position: non_neg_integer(),
          entry_price: float() | nil,
          trades: list(trade())
        }

  @type trade :: {:buy | :sell, float(), DateTime.t()}

  @doc """
  Creates a new portfolio with the specified starting cash.
  
  ## Examples
      iex> IbkrApi.Backtester.Portfolio.new(50_000.0)
      %IbkrApi.Backtester.Portfolio{cash: 50000.0, position: 0, entry_price: nil, trades: []}
  """
  @spec new(float()) :: t()
  def new(starting_cash \\ 100_000.0) do
    %__MODULE__{cash: starting_cash, position: 0, entry_price: nil, trades: []}
  end

  @doc """
  Executes a buy order if no position is currently held.
  
  ## Parameters
  - `portfolio`: Current portfolio state
  - `price`: Price per share to buy at
  - `timestamp`: Optional timestamp for the trade (defaults to current time)
  
  ## Examples
      iex> portfolio = %IbkrApi.Backtester.Portfolio{cash: 10000.0, position: 0}
      iex> result = IbkrApi.Backtester.Portfolio.buy(portfolio, 150.0)
      iex> result.cash
      9850.0
      iex> result.position
      1
      iex> result.entry_price
      150.0
  """
  @spec buy(t(), float(), DateTime.t()) :: t()
  def buy(portfolio, price, timestamp \\ DateTime.utc_now())
  def buy(%__MODULE__{position: 0} = portfolio, price, timestamp) when price > 0 do
    %__MODULE__{
      portfolio
      | position: 1,
        entry_price: price,
        cash: portfolio.cash - price,
        trades: [{:buy, price, timestamp} | portfolio.trades]
    }
  end

  def buy(%__MODULE__{position: position} = portfolio, _price, _timestamp) when position > 0 do
    # Already holding a position, cannot buy more
    portfolio
  end

  @doc """
  Sell shares at the given price if a position is currently held.
  
  ## Parameters
  - `portfolio`: Current portfolio state
  - `price`: Price per share to sell at
  - `timestamp`: Optional timestamp for the trade (defaults to current time)
  
  ## Examples
      iex> portfolio = %IbkrApi.Backtester.Portfolio{cash: 8500.0, position: 1, entry_price: 150.0}
      iex> result = IbkrApi.Backtester.Portfolio.sell(portfolio, 160.0)
      iex> result.cash
      8660.0
      iex> result.position
      0
      iex> result.entry_price
      nil
  """
  @spec sell(t(), float(), DateTime.t()) :: t()
  def sell(portfolio, price, timestamp \\ DateTime.utc_now())
  def sell(%__MODULE__{position: 1} = portfolio, price, timestamp) when price > 0 do
    %__MODULE__{
      portfolio
      | position: 0,
        cash: portfolio.cash + price,
        entry_price: nil,
        trades: [{:sell, price, timestamp} | portfolio.trades]
    }
  end

  def sell(%__MODULE__{position: 0} = portfolio, _price, _timestamp) do
    # No position to sell
    portfolio
  end

  @doc """
  Returns the portfolio unchanged (hold position).
  """
  @spec hold(t()) :: t()
  def hold(%__MODULE__{} = portfolio), do: portfolio

  @doc """
  Calculates the current total value of the portfolio.
  
  ## Parameters
  - `portfolio`: Current portfolio state
  - `current_price`: Current market price of the held security (if any)
  
  ## Examples
      iex> portfolio = %IbkrApi.Backtester.Portfolio{cash: 8500.0, position: 1, entry_price: 150.0}
      iex> IbkrApi.Backtester.Portfolio.total_value(portfolio, 160.0)
      8660.0
  """
  @spec total_value(t(), float()) :: float()
  def total_value(%__MODULE__{cash: cash, position: 0}, _current_price) do
    cash
  end

  def total_value(%__MODULE__{cash: cash, position: position}, current_price) when position > 0 do
    cash + (position * current_price)
  end

  @doc """
  Calculates the unrealized P&L for the current position.
  
  Returns 0.0 if no position is held.
  """
  @spec unrealized_pnl(t(), float()) :: float()
  def unrealized_pnl(%__MODULE__{position: 0}, _current_price), do: 0.0

  def unrealized_pnl(%__MODULE__{position: position, entry_price: entry_price}, current_price) 
      when position > 0 and not is_nil(entry_price) do
    position * (current_price - entry_price)
  end

  @doc """
  Calculates the realized P&L from completed trades.
  
  Only considers buy/sell pairs, ignoring any open position.
  """
  @spec realized_pnl(t()) :: float()
  def realized_pnl(%__MODULE__{trades: trades}) do
    trades
    |> Enum.reverse()
    |> calculate_realized_pnl(0.0, nil)
  end

  # Private helper to calculate realized P&L from trade pairs
  defp calculate_realized_pnl([], pnl, _buy_price), do: pnl

  defp calculate_realized_pnl([{:buy, price, _ts} | rest], pnl, nil) do
    calculate_realized_pnl(rest, pnl, price)
  end

  defp calculate_realized_pnl([{:sell, price, _ts} | rest], pnl, buy_price) when not is_nil(buy_price) do
    trade_pnl = price - buy_price
    calculate_realized_pnl(rest, pnl + trade_pnl, nil)
  end

  defp calculate_realized_pnl([_trade | rest], pnl, buy_price) do
    # Skip unmatched trades
    calculate_realized_pnl(rest, pnl, buy_price)
  end

  @doc """
  Returns portfolio performance statistics.
  
  ## Parameters
  - `portfolio`: Current portfolio state
  - `current_price`: Current market price (for unrealized P&L calculation)
  - `starting_value`: Initial portfolio value (defaults to 100,000.0)
  """
  @spec performance_stats(t(), float(), float()) :: map()
  def performance_stats(%__MODULE__{} = portfolio, current_price, starting_value \\ 100_000.0) do
    total_val = total_value(portfolio, current_price)
    realized = realized_pnl(portfolio)
    unrealized = unrealized_pnl(portfolio, current_price)
    total_return = total_val - starting_value
    return_pct = (total_return / starting_value) * 100.0

    %{
      total_value: total_val,
      total_return: total_return,
      return_percent: return_pct,
      realized_pnl: realized,
      unrealized_pnl: unrealized,
      total_trades: length(portfolio.trades),
      cash: portfolio.cash,
      position: portfolio.position,
      entry_price: portfolio.entry_price
    }
  end
end
