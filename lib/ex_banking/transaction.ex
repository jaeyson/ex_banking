defmodule ExBanking.Transaction do
  use GenServer

  alias ExBanking.State

  @moduledoc false

  def start_link(init) do
    GenServer.start_link(__MODULE__, init, name: __MODULE__)
  end

  def create_user(user) do
    GenServer.call(__MODULE__, {:create_user, user})
  end

  def deposit(user, amount, currency) do
    GenServer.call(__MODULE__, {:deposit, user, amount, currency}, 480_000)
  end

  def withdraw(user, amount, currency) do
    GenServer.call(__MODULE__, {:withdraw, user, amount, currency}, 480_000)
  end

  def get_balance(user, currency) do
    GenServer.call(__MODULE__, {:get_balance, user, currency}, 480_000)
  end

  def send(from_user, to_user, amount, currency) do
    GenServer.call(__MODULE__, {:send, from_user, to_user, amount, currency}, 480_000)
  end

  @impl true
  def init(_args) do
    State.init()
    {:ok, %{}}
  end

  @impl true
  def handle_call({:create_user, user}, _from, _state) do
    new_state = State.add_user(user)
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call({:deposit, user, amount, currency}, _from, _state) do
    attrs = %{user: user, amount: amount, currency: currency}
    rate_limit = State.get_rate_limit(user)
    new_state = State.deposit(user, attrs, rate_limit)
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call({:withdraw, user, amount, currency}, _from, _state) do
    attrs = %{user: user, amount: amount, currency: currency}
    rate_limit = State.get_rate_limit(user)
    new_state = State.withdraw(user, attrs, rate_limit)
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call({:get_balance, user, currency}, _from, _state) do
    rate_limit = State.get_rate_limit(user)
    new_state = State.get_balance(user, currency, rate_limit)
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call({:send, from_user, to_user, amount, currency}, _from, _state) do
    attrs = %{
      sender: from_user,
      receiver: to_user,
      amount: amount,
      currency: currency
    }

    sender_rate_limit = State.get_rate_limit(from_user)
    receiver_rate_limit = State.get_rate_limit(to_user)
    rate_limit = [sender_rate_limit, receiver_rate_limit]
    new_state = State.send(attrs, rate_limit)
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
