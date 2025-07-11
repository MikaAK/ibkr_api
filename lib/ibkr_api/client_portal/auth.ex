defmodule IbkrApi.ClientPortal.Auth do
  defmodule ReauthenticateResponse do
    defstruct message: nil
  end

  defmodule EndSessionResponse do
    defstruct status: nil
  end

  defmodule ServerInfo do
    defstruct server_name: nil, server_version: nil
  end

  defmodule CheckAuthStatusResponse do
    defstruct authenticated: nil, competing: nil, connected: nil,
              fail: nil, hardware_info: nil, mac: nil, message: nil,
              server_info: %IbkrApi.ClientPortal.Auth.ServerInfo{}
  end

  defmodule IServer do
    defstruct auth_status: %IbkrApi.ClientPortal.Auth.CheckAuthStatusResponse{}
  end

  defmodule PingServerResponse do
    defstruct collision: nil, hmds: %{}, iserver: %IbkrApi.ClientPortal.Auth.IServer{},
              session: nil, sso_expires: nil, user_id: nil
  end

  defmodule ValidateSSOResponse do
    defstruct auth_time: nil, credential: nil, expires: nil, features: %{},
              ip: nil, is_free_trial: nil, is_master: nil, landing_app: nil,
              last_accessed: nil, qualified_for_mobile_auth: nil, region: nil,
              result: nil, sf_enabled: nil, user_id: nil, user_name: nil
  end

  alias IbkrApi.HTTP

  @base_url IbkrApi.Config.base_url()

  @spec reauthenticate() :: ErrorMessage.t_res()
  def reauthenticate do
    with {:ok, response} <- HTTP.post(Path.join(@base_url, "iserver/reauthenticate"), %{}) do
      {:ok, struct(ReauthenticateResponse, response)}
    end
  end

  @spec end_session() :: ErrorMessage.t_res()
  def end_session do
    with {:ok, response} <- HTTP.post(Path.join(@base_url, "logout"), %{}) do
      {:ok, struct(EndSessionResponse, response)}
    end
  end

  @spec validate_sso() :: ErrorMessage.t_res()
  def validate_sso do
    with {:ok, response} <- HTTP.get(Path.join(@base_url, "sso/validate")) do
      {:ok, struct(ValidateSSOResponse, response)}
    end
  end

  @spec check_auth_status() :: ErrorMessage.t_res()
  def check_auth_status do
    with {:ok, response} <- HTTP.post(Path.join(@base_url, "iserver/auth/status"), %{}) do
      {:ok, struct(CheckAuthStatusResponse, response)}
    end
  end

  @spec ping_server() :: ErrorMessage.t_res()
  def ping_server do
    with {:ok, response} <- HTTP.post(Path.join(@base_url, "tickle"), %{}) do
      case response do
        %{hmds: %{error: "no bridge"}} ->
          {:ok, PingServerResponse
            |> struct(response)
            |> update_in([Access.key(:iserver), Access.key(:auth_status)], &struct(CheckAuthStatusResponse, &1))
            |> update_in([Access.key(:iserver)], &struct(IServer, &1))}

        response ->
          {:ok, PingServerResponse
            |> struct(response)
            |> update_in([Access.key(:iserver), Access.key(:auth_status), Access.key(:server_info)], &struct(ServerInfo, &1))
            |> update_in([Access.key(:iserver), Access.key(:auth_status)], &struct(CheckAuthStatusResponse, &1))
            |> update_in([Access.key(:iserver)], &struct(IServer, &1))}
      end
    end
  end
end
