# defmodule IbkrApi.Order do
#   alias IbkrApi.HTTP

#   @base_url "https://localhost:5000/v1/api"

#   defmodule OrderDetails do
#     defstruct [
#       acct_id: nil,
#       conid: nil,
#       conidex: nil,
#       sec_type: nil,
#       c_oid: nil,
#       parent_id: nil,
#       order_type: nil,
#       listing_exchange: nil,
#       is_single_group: nil,
#       outside_rth: nil,
#       price: nil,
#       aux_price: nil,
#       side: nil,
#       ticker: nil,
#       tif: nil,
#       trailing_amt: nil,
#       trailing_type: nil,
#       referrer: nil,
#       quantity: nil,
#       cash_qty: nil,
#       fx_qty: nil,
#       use_adaptive: nil,
#       is_ccy_conv: nil,
#       allocation_method: nil,
#       manual_order_time: nil,
#       deactivated: nil,
#       strategy: nil,
#       strategy_parameters: nil
#     ]
#   end

#   defmodule OrderResponse do
#     defstruct [
#       order_id: nil,
#       order_status: nil,
#       encrypt_message: nil,
#       id: nil,
#       message: nil,
#       is_suppressed: nil,
#       message_ids: nil,
#       msg: nil,
#       conid: nil,
#       account: nil
#     ]
#   end


#   def place_order(token, account_id, %OrderDetails{} = order_details) do
#     "#{@base_url}/iserver/account/#{account_id}/orders"
#       |> HTTP.post(order_details, auth_header(token))
#       |> handle_order_response
#   end

#   def modify_order(token, account_id, order_id, %OrderDetails{} = new_order_details) do
#     "#{@base_url}/iserver/account/#{account_id}/order/#{order_id}"
#       |> HTTP.post(new_order_details, auth_header(token))
#       |> handle_order_response
#   end

#   def cancel_order(token, account_id, order_id) do
#     "#{@base_url}/iserver/account/#{account_id}/order/#{order_id}"
#       |> HTTP.delete(auth_header(token))
#       |> handle_order_response
#   end

#   defp auth_header(token) do
#     [{"Authorization", "Bearer #{token}"}]
#   end

#   defp handle_order_response({:ok, response}), do: {:ok, struct(OrderResponse, response)}
#   defp handle_order_response({:error, _} = e), do: e
# end
