defmodule IbkrApi.AssetClass do
  @moduledoc """
  Asset class module for IBKR Client Portal API.
  """

  @asset_classes [
    stock: "STK",
    option: "OPT",
    future: "FUT",
    forex: "SWP",
    warrent: "WAR",
    contract_for_difference: "CFD",
    mutual_fund: "FND",
    bond: "BND",
    inter_commodity_spread: "ICS",
  ]

  for {asset_name, ibkr_asset_class} <- @asset_classes do
    def unquote(asset_name)(), do: unquote(ibkr_asset_class)
  end
end
