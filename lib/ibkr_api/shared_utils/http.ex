defmodule IbkrApi.SharedUtils.HTTP do
  @moduledoc """
  Utility functions to deal with HTTP responses

  To use this we must first stick this into our application.ex
  if we want to use the default pooling setup

  ```elixir
  children = [SharedUtils.HTTP]
  ```

  The other way to use this is to create a child_spec on another module and use
  this to setup your own module

  ### Example

  ```elixir
  defmodule MyThingHttp do
    @app_name :my_thing_http

    # Pool settings are https://hexdocs.pm/finch/0.7.0/Finch.html#child_spec/1
    # size - Number of connections per pool (think http connections)
    # count - Number of pools
    @default_opts [
      name: @app_name,
      atomize_keys?: true,
      pools: [
        "google.ca": [size: 10, count: 20],

        default: [
          size: 10,
          count: 10,
          conn_max_idle_time: 500,
          conn_opts: [transport_opts: [timeout: :timer.seconds(5)]]
        ]
      ]
    ]

    def child_spec(opts), do: SharedUtils.HTTP.child_spec({@app_name, opts})

    def get(url, headers \\ [], opts \\ []) do
      SharedUtils.HTTP.get(url, headers, Keyword.merge(opts, @default_opts))
    end
  end
  ```

  Then in your code you can use

  ```elixir
  {:ok, %SharedUtils.HTTP.Response{body: body}} = MyThingHttp.get("google.ca")
  ```
  """

  require Logger

  alias IbkrApi.SharedUtils

  @default_name :http_shared
  @default_pool_config [size: 10]
  @default_options [
    name: @default_name,
    disable_json_decoding?: false,
    disable_json_encoding?: false,
    follow_redirects?: false,
    atomize_keys?: false,
    http: [get: nil, post: nil, sandbox: Mix.env() === :test],
    pools: [default: @default_pool_config]
  ]

  @definition [
    name: [type: :atom, default: :http_shared],
    atomize_keys?: [type: :boolean, default: false],
    disable_json_decoding?: [type: :boolean, default: false],
    disable_json_encoding?: [type: :boolean, default: false],
    follow_redirects?: [type: :boolean, default: false],
    params: [type: :any],
    stream: [type: {:fun, 2}],
    stream_origin_callback: [type: {:fun, 1}],
    stream_acc: [type: :any],
    receive_timeout: [type: :pos_integer],
    pools: [
      # It's a map
      type: :any,
      default: %{default: [size: 10]}
    ],
    http: [
      type: :keyword_list,
      default: [get: nil, post: nil, sandbox: Mix.env() === :test]
    ]
  ]

  defmodule Response do
    @moduledoc false
    defstruct [
      :status,
      body: "",
      headers: [],
      request: %Finch.Request{
        host: "",
        body: "",
        query: "",
        path: "/",
        port: 80,
        method: "",
        scheme: nil,
        headers: []
      }
    ]

    @type t :: %__MODULE__{}
  end

  @type t_res :: ErrorMessage.t_res({map | Enum.t(), Response.t()} | Response.t())
  @type headers :: [{String.t() | atom, String.t()}]

  @spec start_link() :: GenServer.on_start()
  @spec start_link(atom) :: GenServer.on_start()
  @spec start_link(atom, Keyword.t()) :: GenServer.on_start()
  def start_link(name \\ @default_name, opts \\ []) do
    opts
    |> Keyword.put(:name, name)
    |> NimbleOptions.validate!(@definition)
    |> Keyword.update!(:pools, &ensure_default_pool_exists/1)
    |> Finch.start_link()
  end

  defp ensure_default_pool_exists(pool_configs) when is_list(pool_configs) do
    pool_configs |> Map.new() |> ensure_default_pool_exists
  end

  defp ensure_default_pool_exists(%{default: _} = pool_config), do: pool_config

  defp ensure_default_pool_exists(pool_config) do
    Map.put(pool_config, :default, @default_pool_config)
  end

  def child_spec(name) when is_atom(name) do
    %{
      id: name,
      start: {SharedUtils.HTTP, :start_link, [name]}
    }
  end

  def child_spec({name, opts}) do
    %{
      id: name,
      start: {SharedUtils.HTTP, :start_link, [name, opts]}
    }
  end

  def child_spec(opts) do
    opts = Keyword.put_new(opts, :name, @default_name)

    %{
      id: opts[:name],
      start: {SharedUtils.HTTP, :start_link, [opts[:name], opts]}
    }
  end

  def make_head_request(url, headers, options) do
    request = Finch.build(:head, url, headers)

    make_request(request, options)
  end

  def make_get_request(url, headers, options) do
    request = Finch.build(:get, url, headers)

    make_request(request, options)
  end

  def make_delete_request(url, headers, options) do
    request = Finch.build(:delete, url, headers)

    make_request(request, options)
  end

  def make_post_request(url, body, headers, options) do
    request = Finch.build(:post, url, headers, body)

    make_request(request, options)
  end

  def make_put_request(url, body, headers, options) do
    request = Finch.build(:put, url, headers, body)

    make_request(request, options)
  end

  defp make_request(request, options) do
    if options[:stream] do
      Finch.stream(request, options[:name], options[:stream_acc] || [], options[:stream], options)
    else
      with {:ok, response} <- Finch.request(request, options[:name], options) do
        {:ok,
         %Response{
           request: request,
           body: response.body,
           status: response.status,
           headers: response.headers
         }}
      end
    end
  end

  defp append_query_params(url, nil), do: url

  defp append_query_params(url, params) do
    "#{url}?#{params |> encode_query_params |> Enum.join("&")}"
  end

  defp encode_query_params(params) do
    Enum.flat_map(params, fn
      {k, v} when is_list(v) -> Enum.map(v, &encode_key_value(k, &1))
      {k, v} -> [encode_key_value(k, v)]
    end)
  end

  defp encode_key_value(key, value), do: URI.encode_query(%{key => value})

  @spec post(String.t(), map | String.t()) :: t_res
  @spec post(String.t(), map | String.t(), headers) :: t_res
  @spec post(String.t(), map | String.t(), headers, Keyword.t()) :: t_res
  def post(url, body, headers \\ [], options \\ []) do
    options = @default_options |> Keyword.merge(options) |> NimbleOptions.validate!(@definition)
    http_post = options[:http][:post] || (&make_post_request/4)
    sandbox? = options[:http][:sandbox]

    if sandbox? && !sandbox_disabled?() do
      sandbox_post_response(url, body, headers, options)
    else
      try do
        fn ->
          url
          |> append_query_params(options[:params])
          |> http_post.(serialize_body(body, headers, options), headers, options)
        end
        |> run_and_measure(headers, options)
        |> handle_response(options)
      rescue
        # Nimble pool out of workers error
        RuntimeError -> {:error, ErrorMessage.service_unavailable("Out of HTTP workers")}

      catch
        :exit, reason ->
          {:error,
          ErrorMessage.service_unavailable("SharedUtils.HTTP post exited: #{inspect(reason)}")}
      end
    end
  end

  @spec put(String.t(), map | String.t()) :: t_res
  @spec put(String.t(), map | String.t(), headers) :: t_res
  @spec put(String.t(), map | String.t(), headers, Keyword.t()) :: t_res
  def put(url, body, headers \\ [], options \\ []) do
    options = @default_options |> Keyword.merge(options) |> NimbleOptions.validate!(@definition)
    http_put = options[:http][:put] || (&make_put_request/4)
    sandbox? = options[:http][:sandbox]

    if sandbox? && !sandbox_disabled?() do
      sandbox_put_response(url, body, headers, options)
    else
      try do
        fn ->
          url
          |> append_query_params(options[:params])
          |> http_put.(serialize_body(body, headers, options), headers, options)
        end
        |> run_and_measure(headers, options)
        |> handle_response(options)
      rescue
        # Nimble pool out of workers error
        RuntimeError -> {:error, ErrorMessage.service_unavailable("Out of HTTP workers")}

      catch
        :exit, reason ->
          {:error,
          ErrorMessage.service_unavailable("SharedUtils.HTTP post exited: #{inspect(reason)}")}
      end
    end
  end

  defp serialize_body(params, headers, options) when is_list(params) or is_map(params) do
    content_type = :proplists.get_all_values("content-type", headers) ++
                   :proplists.get_all_values("Content-Type", headers)

    case content_type do
      ["application/x-www-form-urlencoded" | _] -> URI.encode_query(params)

      _ ->
        if options[:disable_json_encoding?] do
          params
        else
          Jason.encode!(params)
        end
    end
  end

  defp serialize_body(params, _headers, _options), do: params

  @spec head(String.t()) :: t_res
  @spec head(String.t(), headers) :: t_res
  @spec head(String.t(), headers, Keyword.t()) :: t_res
  def head(url, headers \\ [], options \\ []) do
    options = @default_options |> Keyword.merge(options) |> NimbleOptions.validate!(@definition)
    http_head = options[:http][:head] || (&make_head_request/3)
    sandbox? = options[:http][:sandbox]

    if sandbox? && !sandbox_disabled?() do
      sandbox_head_response(url, headers, options)
    else
      try do
        fn ->
          url
          |> append_query_params(options[:params])
          |> http_head.(headers, options)
        end
        |> run_and_measure(headers, options)
        |> handle_response(options)
      rescue
        # Nimble pool out of workers error
        RuntimeError -> {:error, ErrorMessage.service_unavailable("Out of HTTP workers")}
      catch
        # Nimble pool out of workers error
        :exit, _ -> {:error, ErrorMessage.service_unavailable("Out of HTTP workers")}
      end
    end
  end

  @spec get(String.t()) :: t_res
  @spec get(String.t(), headers) :: t_res
  @spec get(String.t(), headers, Keyword.t()) :: t_res
  def get(url, headers \\ [], options \\ []) do
    options = @default_options |> Keyword.merge(options) |> NimbleOptions.validate!(@definition)
    http_get = options[:http][:get] || (&make_get_request/3)
    sandbox? = options[:http][:sandbox]

    if sandbox? && !sandbox_disabled?() do
      sandbox_get_response(url, headers, options)
    else
      try do
        fn ->
          url
          |> append_query_params(options[:params])
          |> http_get.(headers, options)
        end
        |> run_and_measure(headers, options)
        |> handle_response(options)
      rescue
        # Nimble pool out of workers error
        RuntimeError -> {:error, ErrorMessage.service_unavailable("Out of HTTP workers")}

      catch
        :exit, reason ->
          {:error,
          ErrorMessage.service_unavailable("SharedUtils.HTTP get exited: #{inspect(reason)}")}
      end
    end
  end

  @spec delete(String.t()) :: t_res
  @spec delete(String.t(), headers) :: t_res
  @spec delete(String.t(), headers, Keyword.t()) :: t_res
  def delete(url, headers \\ [], options \\ []) do
    options = @default_options |> Keyword.merge(options) |> NimbleOptions.validate!(@definition)
    http_delete = options[:http][:delete] || (&make_delete_request/3)
    sandbox? = options[:http][:sandbox]

    if sandbox? && !sandbox_disabled?() do
      sandbox_delete_response(url, headers, options)
    else
      try do
        fn ->
          url
          |> append_query_params(options[:params])
          |> http_delete.(headers, options)
        end
        |> run_and_measure(headers, options)
        |> handle_response(options)
      rescue
        # Nimble pool out of workers error
        RuntimeError -> {:error, ErrorMessage.service_unavailable("Out of HTTP workers")}

      catch
        :exit, reason ->
          {:error,
          ErrorMessage.service_unavailable("SharedUtils.HTTP get exited: #{inspect(reason)}")}
      end
    end
  end

  if Mix.env() === :test do
    defdelegate sandbox_head_response(url, headers, options),
      to: SharedUtils.Support.HTTPSandbox,
      as: :head_response

    defdelegate sandbox_get_response(url, headers, options),
      to: SharedUtils.Support.HTTPSandbox,
      as: :get_response

    defdelegate sandbox_delete_response(url, headers, options),
      to: SharedUtils.Support.HTTPSandbox,
      as: :delete_response

    defdelegate sandbox_post_response(url, body, headers, options),
      to: SharedUtils.Support.HTTPSandbox,
      as: :post_response

    defdelegate sandbox_put_response(url, body, headers, options),
      to: SharedUtils.Support.HTTPSandbox,
      as: :put_response

    defdelegate sandbox_disabled?, to: SharedUtils.Support.HTTPSandbox
  else
    defp sandbox_head_response(url, _, _) do
      raise """
      Cannot use HTTPSandbox outside of test
      url requested: #{inspect(url)}
      """
    end

    defp sandbox_get_response(url, _, _) do
      raise """
      Cannot use HTTPSandbox outside of test
      url requested: #{inspect(url)}
      """
    end

    defp sandbox_delete_response(url, _, _) do
      raise """
      Cannot use HTTPSandbox outside of test
      url requested: #{inspect(url)}
      """
    end

    defp sandbox_post_response(url, _, _, _) do
      raise """
      Cannot use HTTPSandbox outside of test
      url requested: #{inspect(url)}
      """
    end

    defp sandbox_put_response(url, _, _, _) do
      raise """
      Cannot use HTTPSandbox outside of test
      url requested: #{inspect(url)}
      """
    end

    defp sandbox_disabled?, do: true
  end

  defp run_and_measure(fnc, headers, options) do
    start_time = System.monotonic_time()

    response = fnc.()

    metadata = %{
      start_time: System.system_time(),
      request: %{
        method: "GET",
        headers: headers
      },
      response: response,
      options: options
    }

    end_time = System.monotonic_time()
    measurements = %{elapsed_time: end_time - start_time}
    :telemetry.execute([:http, Keyword.get(options, :name)], measurements, metadata)

    response
  end

  defp handle_response({:ok, content}, _opts) when is_binary(content) do
    {:ok, content}
  end

  defp handle_response({:ok, %Response{status: status, body: body} = raw_data}, opts) when status in 200..299 do
    if opts[:disable_json_decoding?] do
      {:ok, {body, raw_data}}
    else
      case Jason.decode(body) do
        {:ok, decoded} ->
          decoded
          |> ProperCase.to_snake_case()
          |> maybe_atomize_keys(opts)
          |> then(&{:ok, {&1, raw_data}})

        {:error, e} ->
          {:error,
           ErrorMessage.internal_server_error("API did not return valid JSON", %{error: e})}
      end
    end
  end

  defp handle_response({:ok, %Response{status: status, headers: headers} = raw_data}, opts) when status in 300..399 do
    if opts[:follow_redirects?] do
      case :proplists.get_value("location", headers) do
        :undefined ->
          {:error, apply(
            ErrorMessage,
            ErrorMessage.http_code_reason_atom(status),
            ["redirected and no location header found", %{response: raw_data, api_name: opts[:name]}]
          )}

        url ->
          case raw_data.request.method do
            "POST" ->
              url
                |> maybe_add_host(raw_data.request)
                |> post(raw_data.body, preserve_header_cookies(raw_data.request.headers, headers), opts)

            "PUT" ->
              url
                |> maybe_add_host(raw_data.request)
                |> put(raw_data.body, preserve_header_cookies(raw_data.request.headers, headers), opts)

            _ ->
              url
                |> maybe_add_host(raw_data.request)
                |> get(preserve_header_cookies(raw_data.request.headers, headers), opts)
          end
      end
    else
      {:error, apply(
        ErrorMessage,
        ErrorMessage.http_code_reason_atom(status),
        ["redirected", %{response: raw_data, api_name: opts[:name]}]
      )}
    end
  end

  defp handle_response({:ok, %{status: code} = res}, opts) do
    api_name = opts[:name]
    details = %{response: res, http_code: code, api_name: api_name}
    error_code_map = error_code_map(api_name)

    if Map.has_key?(error_code_map, code) do
      {error, message} = Map.get(error_code_map, code)

      {:error, apply(ErrorMessage, error, [message, details])}
    else
      message = unknown_error_message(api_name)
      {:error, ErrorMessage.internal_server_error(message, details)}
    end
  end

  defp handle_response({:error, e}, opts) when is_binary(e) or is_atom(e) do
    message = "#{opts[:name]}: #{e}"
    {:error, ErrorMessage.internal_server_error(message, %{error: e})}
  end

  defp handle_response({:error, %Mint.TransportError{reason: :timeout} = e}, opts) do
    message = "#{opts[:name]}: Endpoint timedout"
    {:error, ErrorMessage.request_timeout(message, %{error: e})}
  end

  defp handle_response({:error, e}, opts) do
    message = unknown_error_message(opts[:name])
    {:error, ErrorMessage.internal_server_error(message, %{error: e})}
  end

  defp handle_response(e, opts) do
    message = unknown_error_message(opts[:name])
    {:error, ErrorMessage.internal_server_error(message, %{error: e})}
  end

  defp maybe_add_host(url, %Finch.Request{scheme: scheme, host: host}) do
    no_host? = url |> URI.parse |> Map.get(:host) |> is_nil

    if no_host? do
      Path.join("#{scheme}://#{host}", url)
    else
      url
    end
  end

  def preserve_header_cookies(request_headers, response_headers) do
    new_cookies = "set-cookie"
      |> :proplists.get_all_values(response_headers)
      |> Stream.concat(:proplists.get_all_values("set-cookie", request_headers))
      |> Enum.map(&String.replace(&1, ~r/;.*/, ""))

    if Enum.empty?(new_cookies) do
      request_headers
    else
      merge_new_cookies_header(new_cookies, request_headers)
    end
  end

  defp merge_new_cookies_header(new_cookies, request_headers) do
    case :proplists.get_value("cookie", request_headers) do
      :undefined -> [{"cookie", Enum.join(new_cookies, "; ")} | request_headers]
      cookie ->
        cookie = Enum.reduce(new_cookies, cookie, &append_or_update_cookie/2)

        [{"cookie", cookie} | :proplists.delete("cookie", request_headers)]
    end
  end

  defp append_or_update_cookie(cookie, cookies_str) do
    [key, value] = cookie |> String.split("=") |> Enum.take(2)

    if String.contains?(cookies_str, key) do
      String.replace(cookies_str, ~r/#{key}=[^;]+/, "#{key}=#{value}")
    else
      "#{cookie}; #{cookies_str}"
    end
  end

  def unknown_error_message(api_name) do
    "#{api_name}: unknown error occurred"
  end

  def error_code_map(api_name) do
    %{
      301 => {:moved_permanently, "#{api_name}: moved permanent"},
      400 => {:bad_request, "#{api_name}: bad request"},
      401 => {:unauthorized, "#{api_name}: unauthorized request"},
      403 => {:forbidden, "#{api_name}: forbidden"},
      404 => {:not_found, "#{api_name}: there's nothing to see here :("},
      405 => {:method_not_allowed, "#{api_name}: method not allowed"},
      415 => {:unsupported_media_type, "#{api_name}: unsupported media type in request"},
      424 => {:failed_dependency, "#{api_name}: failed dependency"},
      429 => {:too_many_requests, "#{api_name}: exceeded rate limit"},
      500 => {:internal_server_error, "#{api_name}: internal server error during request"},
      502 => {:bad_gateway, "#{api_name}: bad gateway"},
      503 => {:service_unavailable, "#{api_name}: service unavailable"},
      504 => {:gateway_timeout, "#{api_name}: gateway timeout"}
    }
  end

  defp maybe_atomize_keys(res, opts) do
    if opts[:atomize_keys?] do
      atomize_keys(res)
    else
      res
    end
  end

  def request_uri(%Finch.Request{} = request) do
    request
      |> Map.take([:host, :port, :method, :path, :scheme, :query])
      |> Map.update!(:scheme, &to_string/1)
      |> then(&struct(URI, &1))
  end

  @spec atomize_keys(Enum.t()) :: Enum.t()
  def atomize_keys(map) do
    transform_keys(map, fn
      key when is_binary(key) -> String.to_atom(key)
      key -> key
    end)
  end

  defp transform_keys(map, transform_fn) do
    deep_transform(map, fn {k, v} -> {transform_fn.(k), v} end)
  end

  def deep_transform(map, transform_fn) when is_map(map) do
    Enum.reduce(map, %{}, fn {k, v}, acc ->
      case transform_fn.({k, v}) do
        {k, v} -> Map.put(acc, k, deep_transform(v, transform_fn))
        :delete -> acc
      end
    end)
  end

  def deep_transform(list, transform_fn) when is_list(list) do
    Enum.map(list, &deep_transform(&1, transform_fn))
  end

  def deep_transform(value, _), do: value
end

