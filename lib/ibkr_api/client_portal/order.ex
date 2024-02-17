defmodule IbkrApi.ClientPortal.Order do
  defmodule LiveOrder do
    defstruct [:execution_id, :symbol, :side, :order_description, :trade_time, :trade_time_r, :size, :price, :order_ref, :submitter, :exchange, :commission, :net_amount, :account, :acountCode, :company_name, :contract_description_1, :sec_type, :conid, :conidex, :position, :clearing_id, :clearing_name, :liquidation_trade]
  end

  defmodule OrderResponse do
    defstruct [:filters, :orders, :snapshot]
  end

  defmodule OrderPreviewResponse do
    defstruct [:amount, :equity, :initial, :maintenance, :warn, :error]
  end

  defmodule OrderStatusResponse do
    defstruct [:sub_type, :request_id, :order_id, :conidex, :symbol, :side, :contract_description_1, :listing_exchange, :option_acct, :company_name, :size, :total_size, :currency, :account, :order_type, :limit_price, :stop_price, :cum_fill, :order_status, :order_status_description, :tif, :fg_color, :bg_color, :order_not_editable, :editable_fields, :cannot_cancel_order, :outside_rth, :deactivate_order, :use_price_mgmt_algo, :sec_type, :available_chart_periods, :order_description, :order_description_with_contract, :alert_active, :child_order_type, :size_and_fills, :exit_strategy_display_price, :exit_strategy_chart_description, :exit_strategy_tool_availability, :allowed_duplicate_opposite, :order_time, :oca_group_id]
  end

  defmodule ModifyOrderRequest do
    defstruct [
      acct_id: nil,
      conid: nil,
      order_type: nil,
      outside_rth: nil,
      price: nil,
      aux_price: nil,
      side: nil,
      listing_exchange: nil,
      ticker: nil,
      tif: nil,
      quantity: nil,
      deactivated: nil
    ]
  end

  defmodule ModifyOrderResponse do
    defstruct [
      order_id: nil,
      local_order_id: nil,
      order_status: nil
    ]
  end

  defmodule CancelOrderResponse do
    defstruct [
      order_id: nil,
      msg: nil,
      conid: nil,
      account: nil
    ]
  end

  defmodule OrderPreviewRequest do
    defstruct [
      acct_id: nil,
      conid: nil,
      conidex: nil,
      sec_type: nil,
      c_oid: nil,
      parent_id: nil,
      order_type: nil,
      listing_exchange: nil,
      is_single_group: nil,
      outside_rth: nil,
      price: nil,
      aux_price: nil,
      side: nil,
      ticker: nil,
      tif: nil,
      trailing_amt: nil,
      trailing_type: nil,
      referrer: nil,
      quantity: nil,
      cash_qty: nil,
      fx_qty: nil,
      use_adaptive: nil,
      is_ccy_conv: nil,
      allocation_method: nil,
      strategy: nil,
      strategy_parameters: %{}
    ]
  end

  defmodule OrderPreviewResponse do
    defstruct [
      amount: %{},
      equity: %{},
      initial: %{},
      maintenance: %{},
      warn: nil,
      error: nil
    ]
  end

  defmodule OrderRequest do
    defstruct [
      acct_id: nil, conid: nil, conidex: nil, sec_type: nil, c_oid: nil,
      parent_id: nil, order_type: nil, listing_exchange: nil, is_single_group: nil,
      outside_rth: nil, price: nil, aux_price: nil, side: nil, ticker: nil, tif: nil,
      trailing_amt: nil, trailing_type: nil, referrer: nil, quantity: nil, cash_qty: nil,
      fx_qty: nil, use_adaptive: nil, is_ccy_conv: nil, allocation_method: nil,
      strategy: nil, strategy_parameters: %{}
    ]
  end

  defmodule OrderReplyResponse do
    defstruct order_id: nil, order_status: nil, local_order_id: nil
  end

  defmodule OrderPlacementResponse do
    defstruct id: nil, message: []
  end

  alias IbkrApi.HTTP

  @base_url IbkrApi.Config.base_url()

  @spec get_live_orders() :: ErrorMessage.t_res()
  def get_live_orders do
    with {:ok, response} <- HTTP.get(Path.join(@base_url, "iserver/account/orders")) do
      {:ok, struct(OrderResponse, response)}
    end
  end

  @spec get_order_status(String.t()) :: ErrorMessage.t_res()
  def get_order_status(order_id) do
    with {:ok, response} <- HTTP.get(Path.join(@base_url, "iserver/account/order/status/#{order_id}")) do
      {:ok, struct(OrderStatusResponse, response)}
    end
  end

  @spec modify_order(String.t(), String.t(), ModifyOrderRequest.t()) :: ErrorMessage.t_res()
  def modify_order(account_id, order_id, %ModifyOrderRequest{} = modify_order_request) do
    with {:ok, response} <- HTTP.post(Path.join(@base_url, "/iserver/account/#{account_id}/order/#{order_id}"), modify_order_request) do
      {:ok, struct(ModifyOrderResponse, response)}
    end
  end

  @spec cancel_order(String.t(), String.t()) :: ErrorMessage.t_res()
  def cancel_order(account_id, order_id) do
    with {:ok, response} <- HTTP.delete(Path.join(@base_url, "/iserver/account/#{account_id}/order/#{order_id}")) do
      {:ok, struct(CancelOrderResponse, response)}
    end
  end

  @spec preview_order(String.t(), list(OrderPreviewRequest.t())) :: ErrorMessage.t_res()
  def preview_order(account_id, orders) do
    body = %{"orders" => orders}

    with {:ok, response} <- HTTP.post(Path.join(@base_url, "/iserver/account/#{account_id}/orders/whatif"), body) do
      {:ok, struct(OrderPreviewResponse, response)}
    end
  end

  @spec place_orders(String.t(), list(OrderRequest.t())) :: ErrorMessage.t_res()
  def place_orders(account_id, orders) do
    body = %{"orders" => orders}

    with {:ok, response} <- HTTP.post(Path.join(@base_url, "/iserver/account/#{account_id}/orders"), body) do
      {:ok, Enum.map(response, &struct(OrderPlacementResponse, &1))}
    end
  end

  @spec place_orders_for_fa(String.t(), list(OrderRequest.t())) :: ErrorMessage.t_res()
  def place_orders_for_fa(fa_group, orders) do
    body = %{"orders" => orders}
    with {:ok, response} <- HTTP.post(Path.join(@base_url, "/iserver/account/orders/#{fa_group}"), body) do
      {:ok, Enum.map(response, &struct(OrderPlacementResponse, &1))}
    end
  end

  @spec reply_to_order_query(String.t(), boolean) :: ErrorMessage.t_res()
  def reply_to_order_query(reply_id, confirmed) do
    body = %{"confirmed" => confirmed}

    with {:ok, response} <- HTTP.post(Path.join(@base_url, "/iserver/reply/#{reply_id}"), body) do
      {:ok, struct(OrderReplyResponse, response)}
    end
  end
end
