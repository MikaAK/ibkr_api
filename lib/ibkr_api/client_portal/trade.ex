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
    acountCode: nil,
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
  alias IbkrApi.ErrorMessage

  @base_url IbkrApi.Config.base_url()

  @spec list_trades() :: ErrorMessage.t_res()
  def list_trades do
    with {:ok, response} <- HTTP.get(Path.join(@base_url, "/iserver/account/trades")) do
      {:ok, Enum.map(response, &struct(Trade, &1))}
    end
  end
end

