defmodule ConnectFourWeb.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: ConnectFourWeb.GameRegistry},
      {DynamicSupervisor, name: ConnectFourWeb.GameSupervisor, strategy: :one_for_one},

      ConnectFourWebWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:connect_four_web, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ConnectFourWeb.PubSub},
      # Start a worker by calling: ConnectFourWeb.Worker.start_link(arg)
      # {ConnectFourWeb.Worker, arg},
      # Start to serve requests, typically the last entry
      ConnectFourWebWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ConnectFourWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ConnectFourWebWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
