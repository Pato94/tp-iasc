defmodule TpIasc.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start the endpoint when the application starts
      TpIascWeb.Endpoint,
      # Starts a worker by calling: TpIasc.Worker.start_link(arg)
      # {TpIasc.Worker, arg},
      TpIasc.Supervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TpIasc.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    TpIascWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
