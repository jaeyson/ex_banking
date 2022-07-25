defmodule ExBanking.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: ExBanking.Worker.start_link(arg)
      # {ExBanking.Worker, arg}
      {ExBanking.InitState, []},
      {Task.Supervisor, name: ExBanking.TaskSupervisor}
    ]

    opts = [strategy: :one_for_one, name: ExBanking.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
