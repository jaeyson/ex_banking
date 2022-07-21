defmodule ExBanking.DynamicSupervisor do
  use DynamicSupervisor
  alias ExBanking.Transaction

  @moduledoc false

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
    start_child([])
  end

  def start_child(args) do
    spec = {Transaction, args}

    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
