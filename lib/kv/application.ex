defmodule KV.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: KV.TaskSupervisor},
      Supervisor.child_spec({Task, fn -> KV.Server.accept() end}, restart: :permanent),
      {DynamicSupervisor, name: KV.BucketSupervisor, strategy: :one_for_one},
      {KV.Registry, name: KV.Registry}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_all, name: KV.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
