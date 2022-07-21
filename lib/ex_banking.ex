defmodule ExBanking do
  @moduledoc """
  Documentation for `ExBanking`.
  """

  @behaviour ExBankingBehaviour
  alias ExBanking.Transaction

  @typedoc """
  Custom type for transaction errors
  """
  @type transaction_error ::
          {
            :error,
            :wrong_arguments
            | :user_already_exists
            | :user_does_not_exist
            | :not_enough_money
            | :sender_does_not_exist
            | :receiver_does_not_exist
            | :too_many_requests_to_user
            | :too_many_requests_to_sender
            | :too_many_requests_to_receiver
          }

  @type amount :: number
  @type balance :: number
  @type new_balance :: number
  @type from_user_balance :: number
  @type to_user_balance :: number
  @type currency :: String.t()
  @type user :: String.t()
  @type from_user :: String.t()
  @type to_user :: String.t()

  @doc """
  Creates user. Will return a tuple with :error
  if user already exists.

  Requirements:
  - Function creates new user in the system.
  - New user has zero balance of any currency.

  ## Examples

      iex> Bound.create_user("John Smith")
      :ok

      iex> Bound.create_user("John Smith")
      {:error, :user_already_exists}

  """
  @impl true
  @spec create_user(user) :: :ok | transaction_error
  def create_user(user) when is_binary(user) do
    Transaction.create_user(user)
  end

  def create_user(_user), do: {:error, :wrong_arguments}

  @doc """
  Deposits an amount with the currency provided
  by the user.

  Requirements:
  - Increases user’s balance in given `currency` by `amount` value.
  - Returns `new_balance` of the user in given format.

  ## Examples

      iex> ExBanking.create_user("testuser")
      :ok

      iex> ExBanking.deposit("testuser", 1.00, "usd")
      {:ok, 1.00}

  """
  @impl true
  @spec deposit(user, amount, currency) ::
          {:ok, new_balance} | transaction_error
  def deposit(user, amount, currency)
      when is_binary(user) and
             is_number(amount) and
             amount > 0 do
    Transaction.deposit(user, amount / 1, currency)
  end

  def deposit(_user, _amount, _currency), do: {:error, :wrong_arguments}

  @doc """
  Withdraws an amount with the currency provided
  by the user.

  Requirements:
  - Decreases user’s balance in given `currency` by amount `value`.
  - Returns `new_balance` of the user in given format.

  ## Examples

      iex> ExBanking.create_user("John Doe")
      :ok

      iex> ExBanking.deposit("John Doe", 1.00, "usd")
      {:ok, 1.00}

      iex> ExBanking.withdraw("John Doe", 10.00, "usd")
      {:ok, 0.00}

  """
  @impl true
  @spec withdraw(user, amount, currency) ::
          {:ok, new_balance} | transaction_error
  def withdraw(user, amount, currency)
      when is_binary(user) and
             is_number(amount) and
             is_binary(currency) do
    Transaction.withdraw(user, amount, currency)
  end

  def withdraw(_user, _amount, _currency), do: {:error, :wrong_arguments}

  @doc """
  Gets balance amount from user.

  Requirements:
  - Returns `balance` of the user in given format.

  ## Examples

      iex> ExBanking.create_user("user_123")
      :ok

      iex> ExBanking.get_balance("user_123", "usd")
      {:ok, 0.00}

  """
  @impl true
  @spec get_balance(user, currency) ::
          {:ok, balance :: number} | transaction_error
  def get_balance(user, currency)
      when is_binary(user) and
             is_binary(currency) do
    Transaction.get_balance(user, currency)
  end

  def get_balance(_user, _amount, _currency), do: {:error, :wrong_arguments}

  @doc """
  Sends money to another user.

  Requirements:
  - Decreases `from_user`’s balance in given currency by amount value.
  - Increases `to_user`’s balance in given currency by amount value.
  - Returns `balance` of from_user and to_user in given format.

  ## Examples

      iex> ExBanking.send("test_user", "another_user", 25.00, "usd")
      {:ok, "test_user", "another_user", 25.00}

      iex> ExBanking.send("test_user", "nonexistent_user", 25.00, "usd")
      {:error, :receiver_does_not_exist}

  """
  @impl true
  @spec send(from_user, to_user, amount, currency) ::
          {:ok, from_user_balance, to_user_balance} | transaction_error
  def send(from_user, to_user, amount, currency)
      when is_binary(from_user) and
             is_binary(to_user) and
             is_number(amount) and
             is_binary(currency) do
    Transaction.send(from_user, to_user, amount / 1, currency)
  end

  def send(_from_user, _to_user, _amount, _currency), do: {:error, :wrong_arguments}
end
