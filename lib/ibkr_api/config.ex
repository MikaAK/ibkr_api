defmodule IbkrApi.Config do
  def base_url do
    "#{host()}:#{port()}/v1/api"
  end

  def host do
    Application.get_env(:ibkr_api, :host, "http://localhost")
  end

  def port do
    Application.get_env(:ibkr_api, :port, "5050")
  end
end
