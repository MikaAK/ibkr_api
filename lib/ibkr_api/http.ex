defmodule IbkrApi.HTTP do
  alias IbkrApi.SharedUtils

  @app_name :ibkr_http

  @default_opts [
    name: @app_name,
    atomize_keys?: true,
    # follow_redirects?: true,

    pools: [
      default: [
        size: 10,
        count: 10,
        conn_max_idle_time: 500,
        conn_opts: [transport_opts: [
          verify: :verify_none,
          timeout: :timer.seconds(5)
        ]]
      ]
    ]
  ]

  def child_spec(opts) do
    SharedUtils.HTTP.child_spec({@app_name, Keyword.merge(@default_opts, opts)})
  end

  def get(url, headers \\ [], opts \\ []) do
    url
      |> SharedUtils.HTTP.get(add_default_headers(headers), Keyword.merge(opts, @default_opts))
      |> handle_response()
  end

  def post(url, body, headers \\ [], opts \\ []) do
    url
      |> SharedUtils.HTTP.post(body, add_default_headers(headers), Keyword.merge(opts, @default_opts))
      |> handle_response()
  end

  def delete(url, headers \\ [], opts \\ []) do
    url
      |> SharedUtils.HTTP.delete(add_default_headers(headers), Keyword.merge(opts, @default_opts))
      |> handle_response()
  end

  defp add_default_headers(headers), do: [{"Content-Type", "application/json"} | headers]

  defp handle_response({:ok, {response, _raw_data}}) do
    {:ok, response}
  end

  defp handle_response(e) do
    e
  end
end
