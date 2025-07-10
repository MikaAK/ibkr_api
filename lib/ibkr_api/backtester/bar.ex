defmodule IbkrApi.Backtester.Bar do
  @moduledoc """
  Historical market data bar structure for backtesting.
  
  This module provides a standardized bar structure and conversion utilities
  for backtesting with IBKR historical data.
  """

  defstruct [
    :timestamp,
    :open,
    :high,
    :low,
    :close,
    :volume
  ]

  @type t :: %__MODULE__{
          timestamp: DateTime.t(),
          open: float(),
          high: float(),
          low: float(),
          close: float(),
          volume: float()
        }

  @doc """
  Converts IBKR API response data to IbkrApi.Backtester.Bar struct.
  
  ## Parameters
  - `data`: Map containing IBKR bar data with keys "t", "o", "h", "l", "c", "v"
  
  ## Examples
      iex> IbkrApi.Backtester.Bar.from_ibkr(%{"t" => 1707139200000, "o" => 189.9, "h" => 190.3, "l" => 188.7, "c" => 189.5, "v" => 24018321})
      %IbkrApi.Backtester.Bar{
        timestamp: ~U[2024-02-05 13:20:00.000Z],
        open: 189.9,
        high: 190.3,
        low: 188.7,
        close: 189.5,
        volume: 24018321
      }
  """
  @spec from_ibkr(map()) :: t()
  def from_ibkr(%{"t" => ts, "o" => o, "h" => h, "l" => l, "c" => c, "v" => v}) do
    %__MODULE__{
      timestamp: DateTime.from_unix!(ts, :millisecond),
      open: o,
      high: h,
      low: l,
      close: c,
      volume: v
    }
  end

  @doc """
  Converts IbkrApi.ClientPortal.MarketData.HistoricalBar to IbkrApi.Backtester.Bar.
  
  This provides compatibility between the IBKR API module and backtesting framework.
  """
  @spec from_historical_bar(IbkrApi.ClientPortal.MarketData.HistoricalBar.t()) :: t()
  def from_historical_bar(%IbkrApi.ClientPortal.MarketData.HistoricalBar{} = bar) do
    %__MODULE__{
      timestamp: bar.timestamp,
      open: bar.open,
      high: bar.high,
      low: bar.low,
      close: bar.close,
      volume: bar.volume
    }
  end

  @doc """
  Returns the typical price (HLC/3) for the bar.
  """
  @spec typical_price(t()) :: float()
  def typical_price(%__MODULE__{high: h, low: l, close: c}) do
    (h + l + c) / 3.0
  end

  @doc """
  Returns the price range (high - low) for the bar.
  """
  @spec range(t()) :: float()
  def range(%__MODULE__{high: h, low: l}) do
    h - l
  end

  @doc """
  Returns true if the bar is bullish (close > open).
  """
  @spec bullish?(t()) :: boolean()
  def bullish?(%__MODULE__{open: o, close: c}) do
    c > o
  end

  @doc """
  Returns true if the bar is bearish (close < open).
  """
  @spec bearish?(t()) :: boolean()
  def bearish?(%__MODULE__{open: o, close: c}) do
    c < o
  end
end
