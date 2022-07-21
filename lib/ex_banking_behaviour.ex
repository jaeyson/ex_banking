defmodule ExBankingBehaviour do
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

  @callback create_user(user) :: :ok | transaction_error

  @callback deposit(user, amount, currency) ::
              {:ok, new_balance} | transaction_error

  @callback withdraw(user, amount, currency) ::
              {:ok, new_balance} | transaction_error

  @callback get_balance(user, currency) ::
              {:ok, balance :: number} | transaction_error

  @callback send(from_user, to_user, amount, currency) ::
              {:ok, from_user_balance, to_user_balance} | transaction_error
end
