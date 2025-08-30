defmodule IbkrApi.Websocket do
  @moduledoc """
  WebSocket client for Interactive Brokers Client Portal API streaming data.

  This module provides a WebSocket client that connects to the IBKR Client Portal Gateway
  to receive real-time market data, order updates, and portfolio P&L streams.

  ## Usage

  To use this module, create your own module and `use IbkrApi.Websocket`:

      defmodule MyIbkrClient do
        use IbkrApi.Websocket

        def handle_event({:market_data, data}, state) do
          IO.inspect(data, label: "Market Data")
          {:ok, state}
        end

        def handle_event({:order_update, order}, state) do
          IO.inspect(order, label: "Order Update")
          {:ok, state}
        end

        def handle_event({:pnl_update, pnl}, state) do
          IO.inspect(pnl, label: "P&L Update")
          {:ok, state}
        end

        def handle_event(_event, state) do
          {:ok, state}
        end
      end

      # Start the WebSocket client
      {:ok, pid} = MyIbkrClient.start_link(%{})

      # Subscribe to market data for contract ID 8314 (IBM)
      MyIbkrClient.subscribe_to_market_data(pid, [8314], ["31", "83"])

      # Subscribe to order updates
      MyIbkrClient.subscribe_to_order_updates(pid)

      # Subscribe to P&L updates
      MyIbkrClient.subscribe_to_pnl(pid)

  ## Connection Requirements

  Before connecting, ensure:
  1. IBKR Client Portal Gateway is running (usually on localhost:5000)
  2. You are logged in via the Gateway web interface
  3. Your account has appropriate market data subscriptions

  ## Message Formats

  ### Market Data Subscription
  - Subscribe: `smd+<CONID>+{"fields":["31","83"],"tempo":1000,"snapshot":true}`
  - Unsubscribe: `umd+<CONID>+{}`

  ### Order Updates
  - Subscribe: `sor+{}`
  - Unsubscribe: `uor+{}`

  ### P&L Updates
  - Subscribe: `spl+{}`
  - Unsubscribe: `upl+{}`

  ### Heartbeat
  - Send: `ech+hb` (recommended every 10 seconds)

  ## Field IDs for Market Data

  Common field IDs for market data subscriptions:
  - "31": Last price
  - "83": Percent change
  - "84": High
  - "85": Low
  - "86": Volume
  - "87": Close
  - "88": Bid
  - "89": Ask
  - "7295": Market cap
  - "7296": Company name

  ## Rate Limits

  IBKR limits concurrent market data streams to approximately 5 instruments per session.
  Plan your subscriptions accordingly.

  ## SSL Configuration

  The local Gateway uses a self-signed SSL certificate. This module automatically
  configures SSL options to accept self-signed certificates for localhost connections.
  """

  use WebSockex
  require Logger

  @default_gateway_url "wss://#{IbkrApi.Config.host()}:#{IbkrApi.Config.port()}/v1/api/ws"
  @heartbeat_interval 10_000

  @callback handle_event(event :: term(), state :: term()) :: {:ok, term()} | {:error, term()}

  defmacro __using__(_opts) do
    quote do
      use WebSockex
      require Logger

      @behaviour IbkrApi.Websocket

      def start_link(opts \\ []) do
        IbkrApi.Websocket.start_link(__MODULE__, opts)
      end

      def subscribe_to_market_data(pid, contract_ids, fields, opts \\ %{}) do
        IbkrApi.Websocket.subscribe_to_market_data(pid, contract_ids, fields, opts)
      end

      def unsubscribe_from_market_data(pid, contract_ids) do
        IbkrApi.Websocket.unsubscribe_from_market_data(pid, contract_ids)
      end

      def subscribe_to_order_updates(pid) do
        IbkrApi.Websocket.subscribe_to_order_updates(pid)
      end

      def unsubscribe_from_order_updates(pid) do
        IbkrApi.Websocket.unsubscribe_from_order_updates(pid)
      end

      def subscribe_to_pnl(pid) do
        IbkrApi.Websocket.subscribe_to_pnl(pid)
      end

      def unsubscribe_from_pnl(pid) do
        IbkrApi.Websocket.unsubscribe_from_pnl(pid)
      end

      def send_heartbeat(pid) do
        IbkrApi.Websocket.send_heartbeat(pid)
      end

      # Read-only helpers to introspect the WebSocket process state
      def get_session(pid) do
        IbkrApi.Websocket.get_session(pid)
      end

      # Default implementation - users should override this
      def handle_event(_event, state) do
        {:ok, state}
      end

      defoverridable handle_event: 2
    end
  end

  @doc """
  Starts a WebSocket connection to the IBKR Client Portal Gateway.

  ## Options

  - `:url` - WebSocket URL (default derived from `IbkrApi.Config`)
  - `:ssl_opts` - SSL options for the connection
  - `:heartbeat` - Whether to send automatic heartbeats (default: true)
  - `:initial_state` - Initial user state (default: `%{}`)
  """
  def start_link(module, opts \\ []) do
    url = Keyword.get(opts, :url, @default_gateway_url)
    ssl_opts = Keyword.get(opts, :ssl_opts, default_ssl_opts(url))
    heartbeat = Keyword.get(opts, :heartbeat, true)
    initial_state = Keyword.get(opts, :initial_state, %{})

    state = %{
      module: module,
      user_state: initial_state,
      heartbeat: heartbeat,
      subscriptions: %{},
      session: %{}
    }

    websocket_opts = [
      ssl_opts: ssl_opts,
      extra_headers: [
        {"User-Agent", "IbkrApi-Elixir/1.0.1"}
      ]
    ]

    case WebSockex.start_link(url, __MODULE__, state, websocket_opts) do
      {:ok, pid} ->
        if heartbeat do
          schedule_heartbeat()
        end
        {:ok, pid}
      error ->
        error
    end
  end

  @doc """
  Subscribes to market data for the given contract IDs.

  ## Parameters

  - `pid` - WebSocket process PID
  - `contract_ids` - List of contract IDs to subscribe to
  - `fields` - List of field IDs to request (e.g., ["31", "83"])
  - `opts` - Additional options:
    - `:tempo` - Update frequency in milliseconds (default: 1000)
    - `:snapshot` - Request initial snapshot (default: true)
  """
  def subscribe_to_market_data(pid, contract_ids, fields, opts \\ %{}) do
    tempo = Map.get(opts, :tempo, 1000)
    snapshot = Map.get(opts, :snapshot, true)

    for contract_id <- contract_ids do
      payload = %{
        "fields" => fields,
        "tempo" => tempo,
        "snapshot" => snapshot
      }
      message = "smd+#{contract_id}+#{Jason.encode!(payload)}"
      WebSockex.cast(pid, {:send_message, message})
    end
  end

  @doc """
  Unsubscribes from market data for the given contract IDs.
  """
  def unsubscribe_from_market_data(pid, contract_ids) do
    for contract_id <- contract_ids do
      message = "umd+#{contract_id}+{}"
      WebSockex.cast(pid, {:send_message, message})
    end
  end

  @doc """
  Subscribes to order updates for all accounts in the current session.
  """
  def subscribe_to_order_updates(pid) do
    WebSockex.cast(pid, {:send_message, "sor+{}"})
  end

  @doc """
  Unsubscribes from order updates.
  """
  def unsubscribe_from_order_updates(pid) do
    WebSockex.cast(pid, {:send_message, "uor+{}"})
  end

  @doc """
  Subscribes to portfolio P&L updates.
  """
  def subscribe_to_pnl(pid) do
    WebSockex.cast(pid, {:send_message, "spl+{}"})
  end

  @doc """
  Unsubscribes from portfolio P&L updates.
  """
  def unsubscribe_from_pnl(pid) do
    WebSockex.cast(pid, {:send_message, "upl+{}"})
  end

  @doc """
  Sends a heartbeat message to keep the connection alive.
  """
  def send_heartbeat(pid) do
    WebSockex.cast(pid, {:send_message, "ech+hb"})
  end

  @doc """
  Returns the stored session/auth/system information tracked by the WebSocket process.
  """
  def get_session(pid, timeout \\ 5_000) do
    ref = make_ref()
    WebSockex.cast(pid, {:get_session, {self(), ref}})
    receive do
      {^ref, session} -> session
    after
      timeout -> {:error, :timeout}
    end
  end

  def handle_connect(_conn, state) do
    Logger.info("Connected to IBKR WebSocket")
    {:ok, state}
  end

  def handle_disconnect(%{reason: reason}, state) do
    Logger.warning("Disconnected from IBKR WebSocket: #{inspect(reason)}")
    {:ok, state}
  end

  def handle_frame({:text, msg}, state) do
    case Jason.decode(msg) do
      {:ok, data} ->
        event = parse_message(data)
        state = maybe_update_session(state, event)
        case apply(state.module, :handle_event, [event, state.user_state]) do
          {:ok, new_user_state} ->
            {:ok, %{state | user_state: new_user_state}}
          {:error, reason} ->
            Logger.error("Error handling event: #{inspect(reason)}")
            {:ok, state}
        end
      {:error, reason} ->
        Logger.error("Failed to decode WebSocket message: #{inspect(reason)}")
        Logger.debug("Raw message: #{msg}")
        {:ok, state}
    end
  end

  # Some gateways may send binary frames (e.g., compressed or raw JSON). Attempt to decode; if it fails, ignore safely.
  def handle_frame({:binary, msg}, state) do
    case Jason.decode(msg) do
      {:ok, data} ->
        event = parse_message(data)
        state = maybe_update_session(state, event)
        case apply(state.module, :handle_event, [event, state.user_state]) do
          {:ok, new_user_state} ->
            {:ok, %{state | user_state: new_user_state}}
          {:error, reason} ->
            Logger.error("Error handling event (binary): #{inspect(reason)}")
            {:ok, state}
        end
      {:error, _} ->
        Logger.debug("Ignoring non-JSON binary frame: #{inspect(byte_size(msg))} bytes")
        {:ok, state}
    end
  end

  # Gracefully handle ping/pong frames if surfaced
  def handle_frame(:ping, state), do: {:ok, state}
  def handle_frame(:pong, state), do: {:ok, state}
  def handle_frame({:ping, _payload}, state), do: {:ok, state}
  def handle_frame({:pong, _payload}, state), do: {:ok, state}

  # Catch-all to avoid crashes on unexpected frame types
  def handle_frame(frame, state) do
    Logger.debug("Unhandled frame: #{inspect(frame)}")
    {:ok, state}
  end

  def handle_cast({:send_message, message}, state) do
    {:reply, {:text, message}, state}
  end

  def handle_cast({:get_session, {from, ref}}, state) do
    send(from, {ref, state.session})
    {:ok, state}
  end

  def handle_info(:heartbeat, state) do
    if state.heartbeat do
      schedule_heartbeat()
      {:reply, {:text, "ech+hb"}, state}
    else
      {:ok, state}
    end
  end

  def handle_info(msg, state) do
    Logger.debug("Received unexpected message: #{inspect(msg)}")
    {:ok, state}
  end

  # Private functions

  defp default_ssl_opts(url) do
    if String.contains?(url, "localhost") do
      # For localhost connections, disable SSL verification due to self-signed cert
      [
        verify: :verify_none,
        versions: [:"tlsv1.2", :"tlsv1.3"]
      ]
    else
      # For remote connections, use standard SSL verification
      [
        verify: :verify_peer,
        versions: [:"tlsv1.2", :"tlsv1.3"]
      ]
    end
  end

  defp schedule_heartbeat do
    Process.send_after(self(), :heartbeat, @heartbeat_interval)
  end

  defp parse_message(%{"topic" => topic} = data) do
    cond do
      String.starts_with?(topic, "smd+") ->
        parse_market_data(data)

      topic === "sor" or String.starts_with?(topic, "o+") ->
        parse_order_update(data)

      topic === "spl" ->
        parse_pnl_update(data)

      topic === "act" ->
        {:activation, Map.get(data, "args", %{})}

      topic === "sts" ->
        {:status, Map.get(data, "args", %{})}

      topic === "system" ->
        {:system, data}

      Map.has_key?(data, "hb") ->
        {:heartbeat, data}

      true ->
        {:unknown, data}
    end
  end

  defp parse_message(data) do
    {:raw, data}
  end

  defp parse_market_data(%{"topic" => topic, "conid" => conid} = data) do
    # Extract contract ID from topic (e.g., "smd+8314" -> 8314)
    fields = Map.drop(data, ["topic", "conid", "seq"])

    {:market_data, %{
      contract_id: conid,
      topic: topic,
      fields: fields,
      timestamp: System.system_time(:millisecond)
    }}
  end

  defp parse_order_update(data) do
    {:order_update, %{
      topic: Map.get(data, "topic"),
      data: data,
      timestamp: System.system_time(:millisecond)
    }}
  end

  defp parse_pnl_update(%{"args" => args} = data) do
    # P&L data is nested in the "args" field
    pnl_data = case args do
      map when is_map(map) ->
        # Get the first (and usually only) account's P&L data
        case Map.values(map) do
          [first_account | _] -> first_account
          [] -> %{}
        end
      _ -> %{}
    end

    {:pnl_update, %{
      topic: Map.get(data, "topic"),
      daily_pnl: Map.get(pnl_data, "dpl"),
      unrealized_pnl: Map.get(pnl_data, "upl"),
      data: pnl_data,
      timestamp: System.system_time(:millisecond)
    }}
  end

  # Persist selected session/auth/system details into the socket state
  defp maybe_update_session(state, {:activation, args}) when is_map(args) do
    session_update = %{
      accounts: Map.get(args, "accounts"),
      selected_account: Map.get(args, "selectedAccount"),
      acct_props: Map.get(args, "acctProps"),
      allow_features: Map.get(args, "allowFeatures"),
      chart_periods: Map.get(args, "chartPeriods"),
      groups: Map.get(args, "groups"),
      profiles: Map.get(args, "profiles"),
      server_info: Map.get(args, "serverInfo"),
      session_id: Map.get(args, "sessionId")
    }

    put_in(state, [:session], Map.merge(state.session, session_update))
  end

  defp maybe_update_session(state, {:status, args}) when is_map(args) do
    status_update = %{
      auth: %{
        authenticated: Map.get(args, "authenticated"),
        competing: Map.get(args, "competing"),
        connected: Map.get(args, "connected"),
        username: Map.get(args, "username"),
        message: Map.get(args, "message"),
        fail: Map.get(args, "fail"),
        server_name: Map.get(args, "serverName"),
        server_version: Map.get(args, "serverVersion")
      }
    }

    update_in(state.session, &Map.merge(&1, status_update)) |> then(&%{state | session: &1})
  end

  defp maybe_update_session(state, {:system, data}) when is_map(data) do
    sys_update = %{
      system: %{
        is_ft: Map.get(data, "isFT"),
        is_paper: Map.get(data, "isPaper"),
        success: Map.get(data, "success")
      }
    }

    update_in(state.session, &Map.merge(&1, sys_update)) |> then(&%{state | session: &1})
  end

  defp maybe_update_session(state, _), do: state
end
