defmodule IbkrApi.ClientPortal.Trade do
  defstruct [
    execution_id: nil,
    symbol: nil,
    side: nil,
    order_description: nil,
    trade_time: nil,
    trade_time_r: nil,
    size: nil,
    price: nil,
    order_ref: nil,
    submitter: nil,
    exchange: nil,
    commission: nil,
    net_amount: nil,
    account: nil,
    account_code: nil,
    company_name: nil,
    contract_description_1: nil,
    sec_type: nil,
    conid: nil,
    conidex: nil,
    position: nil,
    clearing_id: nil,
    clearing_name: nil,
    liquidation_trade: nil
  ]

  alias IbkrApi.HTTP

  @base_url IbkrApi.Config.base_url()

  @spec list_trades() :: ErrorMessage.t_res()
  def list_trades do
    case HTTP.get(Path.join(@base_url, "/iserver/account/trades")) do
      {:ok, trades} when is_list(trades) ->
        {:ok, Enum.map(trades, &parse_trade/1)}

      {:ok, _other} ->
        {:ok, []}

      error ->
        error
    end
  end

  defp parse_trade(trade_data) do
    %__MODULE__{
      execution_id: trade_data["execution_id"] || trade_data[:execution_id],
      symbol: trade_data["symbol"] || trade_data[:symbol],
      side: trade_data["side"] || trade_data[:side],
      order_description: trade_data["order_description"] || trade_data[:order_description],
      trade_time: trade_data["trade_time"] || trade_data[:trade_time],
      trade_time_r: trade_data["trade_time_r"] || trade_data[:trade_time_r],
      size: trade_data["size"] || trade_data[:size],
      price: trade_data["price"] || trade_data[:price],
      order_ref: trade_data["order_ref"] || trade_data[:order_ref],
      submitter: trade_data["submitter"] || trade_data[:submitter],
      exchange: trade_data["exchange"] || trade_data[:exchange],
      commission: trade_data["commission"] || trade_data[:commission],
      net_amount: trade_data["net_amount"] || trade_data[:net_amount],
      account: trade_data["account"] || trade_data[:account],
      account_code: trade_data["account_code"] || trade_data[:account_code] || trade_data["account_id"] || trade_data[:account_id],
      company_name: trade_data["company_name"] || trade_data[:company_name],
      contract_description_1: trade_data["contract_description_1"] || trade_data[:contract_description_1],
      sec_type: trade_data["sec_type"] || trade_data[:sec_type],
      conid: trade_data["conid"] || trade_data[:conid] || trade_data["contract_id"] || trade_data[:contract_id],
      conidex: trade_data["conidex"] || trade_data[:conidex],
      position: trade_data["position"] || trade_data[:position],
      clearing_id: trade_data["clearing_id"] || trade_data[:clearing_id],
      clearing_name: trade_data["clearing_name"] || trade_data[:clearing_name],
      liquidation_trade: trade_data["liquidation_trade"] || trade_data[:liquidation_trade]
    }
  end
end
