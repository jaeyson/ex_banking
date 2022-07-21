defmodule Bound do
  def create_user(user) do
    ex_banking().create_user(user)
  end

  def deposit(user, amount, currency) do
    ex_banking().deposit(user, amount, currency)
  end

  def withdraw(user, amount, currency) do
    ex_banking().withdraw(user, amount, currency)
  end

  def get_balance(user, currency) do
    ex_banking().get_balance(user, currency)
  end

  def send(from_user, to_user, amount, currency) do
    ex_banking().send(from_user, to_user, amount, currency)
  end

  defp ex_banking do
    Application.get_env(:bound, :ex_banking, ExBanking)
  end
end
