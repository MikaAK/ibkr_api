defmodule Examples.WebsocketClient do
  @moduledoc """
  Example WebSocket client implementation for IBKR streaming data.

  This module demonstrates how to use the IbkrApi.Websocket module to create
  a client that handles real-time market data, order updates, and P&L streams.

  ## Usage

      # Start the client
      {:ok, pid} = Examples.WebsocketClient.start_link(%{})

      # Subscribe to market data for IBM (contract ID 8314)
      Examples.WebsocketClient.subscribe_to_market_data(pid, [8314], ["31", "83"])

      # Subscribe to order updates
      Examples.WebsocketClient.subscribe_to_order_updates(pid)

      # Subscribe to P&L updates
      Examples.WebsocketClient.subscribe_to_pnl(pid)

  ## Event Handling

  This client logs all received events. In a real application, you would
  implement custom logic in the handle_event/2 callback to process the data
  according to your needs.
  """

  use IbkrApi.Websocket
  require Logger

  @doc """
  Handles incoming WebSocket events from IBKR.

  ## Event Types

  - `{:market_data, data}` - Real-time market data updates
  - `{:order_update, order}` - Order status changes
  - `{:pnl_update, pnl}` - Portfolio P&L updates
  - `{:activation, data}` - Connection activation message
  - `{:heartbeat, data}` - Heartbeat acknowledgment
  - `{:unknown, data}` - Unknown message type
  - `{:raw, data}` - Raw message without topic field
  """
  def handle_event({:market_data, data}, state) do
    Logger.info("Market Data Update for Contract #{data.contract_id}")
    Logger.debug("Fields: #{inspect(data.fields)}")
    
    # Extract common fields
    last_price = Map.get(data.fields, "31")
    percent_change = Map.get(data.fields, "83")
    
    if last_price do
      Logger.info("  Last Price: #{last_price}")
    end
    
    if percent_change do
      Logger.info("  Percent Change: #{percent_change}%")
    end
    
    {:ok, state}
  end

  def handle_event({:order_update, order}, state) do
    Logger.info("Order Update: #{inspect(order.topic)}")
    Logger.debug("Order Data: #{inspect(order.data)}")
    {:ok, state}
  end

  def handle_event({:pnl_update, pnl}, state) do
    Logger.info("P&L Update:")
    
    if pnl.daily_pnl do
      Logger.info("  Daily P&L: #{pnl.daily_pnl}")
    end
    
    if pnl.unrealized_pnl do
      Logger.info("  Unrealized P&L: #{pnl.unrealized_pnl}")
    end
    
    Logger.debug("Full P&L Data: #{inspect(pnl.data)}")
    {:ok, state}
  end

  def handle_event({:activation, data}, state) do
    Logger.info("WebSocket connection activated")
    Logger.debug("Activation data: #{inspect(data)}")
    {:ok, state}
  end

  def handle_event({:heartbeat, _data}, state) do
    Logger.debug("Heartbeat received")
    {:ok, state}
  end

  def handle_event({:unknown, data}, state) do
    Logger.warning("Unknown message type received")
    Logger.debug("Unknown data: #{inspect(data)}")
    {:ok, state}
  end

  def handle_event({:raw, data}, state) do
    Logger.warning("Raw message without topic field")
    Logger.debug("Raw data: #{inspect(data)}")
    {:ok, state}
  end

  def handle_event(event, state) do
    Logger.warning("Unhandled event: #{inspect(event)}")
    {:ok, state}
  end
end
