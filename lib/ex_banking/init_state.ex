defmodule ExBanking.InitState do
  use GenServer

  def start_link(init) do
    GenServer.start_link(__MODULE__, init, name: __MODULE__)
  end

  def init(_args) do
    ExBanking.Transaction.init()
    {:ok, []}
  end
end
