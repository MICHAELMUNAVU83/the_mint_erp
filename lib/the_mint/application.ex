defmodule TheMint.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TheMintWeb.Telemetry,
      TheMint.Repo,
      {DNSCluster, query: Application.get_env(:the_mint, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TheMint.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: TheMint.Finch},
      # Start a worker by calling: TheMint.Worker.start_link(arg)
      # {TheMint.Worker, arg},
      # Start to serve requests, typically the last entry
      TheMintWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TheMint.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TheMintWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
