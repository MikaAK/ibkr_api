defmodule IbkrApi.Backtester.Strategy do
  @moduledoc """
  Behaviour for defining backtesting strategies.
  
  Strategies implement the `signal/3` callback to generate buy/sell/hold signals
  based on current market data and historical context.
  """

  @doc """
  Generates a trading signal based on current bar and historical data.
  
  ## Parameters
  - `current_bar`: The current bar being processed
  - `previous_bars`: List of previous bars (most recent first)
  - `state`: Strategy-specific state map for maintaining indicators, etc.
  
  ## Returns
  A tuple containing the signal (`:buy`, `:sell`, or `:hold`) and updated state.
  
  ## Examples
      def signal(bar, prev_bars, state) do
        if bar.close > calculate_sma(prev_bars, 20) do
          {:buy, state}
        else
          {:sell, state}
        end
      end
  """
  @callback signal(
              current_bar :: IbkrApi.Backtester.Bar.t(),
              previous_bars :: [IbkrApi.Backtester.Bar.t()],
              state :: map()
            ) :: {:buy | :sell | :hold, map()}

  @doc """
  Optional callback for strategy initialization.
  
  Called once before backtesting begins. Can be used to set up
  initial state, validate parameters, etc.
  
  Default implementation returns an empty map.
  """
  @callback init(opts :: keyword()) :: map()

  @optional_callbacks init: 1

  # Default implementation for init/1
  defmacro __using__(_opts) do
    quote do
      @behaviour IbkrApi.Backtester.Strategy

      def init(_opts), do: %{}

      defoverridable init: 1
    end
  end
end
