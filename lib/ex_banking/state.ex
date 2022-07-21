defmodule ExBanking.State do
  use Agent
  require Logger

  @moduledoc false
  # @moduledoc since: "0.1.0"

  # This is where we store data. Based acceptance criteria:
  # Application should not use any database / disc
  # storage. All needed data should be stored only in
  # application memory.

  import :mnesia

  @user :user
  @rate_limit :rate_limit
  @default_currency "usd"
  @rate_limit_operations 3

  # These are the fields and indices for
  # User table upon initializing.
  @user_opts [
    attributes: [
      :id,
      :name,
      :balance,
      :currency
    ],
    index: [:name, :currency]
  ]

  @rate_limit_opts [
    attributes: [
      :id,
      :name,
      :rate_limit
    ],
    index: [:name]
  ]

  @doc """
  Initializes mnesia with table and index
  """
  def init do
    start()
    create_table(@user, @user_opts)
    create_table(@rate_limit, @rate_limit_opts)
  end

  @doc """
  Connect to another mnesia node.

  ## Examples

      iex> State.connect_node(:node1@localhost)
      {ok, [:node1@localhost]}

  """
  def connect_node(node_name) do
    Node.connect(node_name)

    # Delete it before connecting from other node
    # otherwise throws merge schema fail
    stop()
    delete_schema([node()])
    start()

    # set to running db
    change_config(:extra_db_nodes, Node.list())

    # persists when a remote node dies
    add_table_copy(@user, node(), :ram_copies)
    add_table_copy(@rate_limit, node(), :ram_copies)

    # :rpc.multicall(Node.list(), :mnesia, :start, [])
  end

  def add_user(user) do
    case get_user(user) do
      {:atomic, []} ->
        id = increment_key()
        user_input = {@user, id, user, 0.00, @default_currency}
        rate_limit = {@rate_limit, id, user, @rate_limit_operations}

        transaction(fn ->
          write(user_input)
          write(rate_limit)
        end)

        :ok

      {:atomic, _} ->
        {:error, :user_already_exists}
    end
  end

  def deposit(user, attrs, rate_limit) do
    case rate_limit === 0 do
      true -> {:error, :too_many_requests_to_user}
      false -> do_deposit(user, attrs)
    end
  end

  def withdraw(user, attrs, rate_limit) do
    case rate_limit === 0 do
      true -> {:error, :too_many_requests_to_user}
      false -> do_withdraw(user, attrs)
    end
  end

  def get_balance(user, currency, rate_limit) do
    case rate_limit === 0 do
      true -> {:error, :too_many_requests_to_user}
      false -> do_get_balance(user, currency)
    end
  end

  def send(attrs, [sender_rate_limit, receiver_rate_limit] = _) do
    case [sender_rate_limit === 0, receiver_rate_limit === 0] do
      [true, false] ->
        {:error, :too_many_requests_to_sender}

      [true, true] ->
        {:error, :too_many_requests_to_sender}

      [false, true] ->
        {:error, :too_many_requests_to_reciever}

      _ ->
        do_send(attrs)
    end
  end

  def do_deposit(user, attrs) do
    update_rate_limit(user, :decrement)

    calculate_balance = fn record, attrs, operation ->
      [balance, record] = prepare_record(record, attrs, operation)

      new_balance =
        case transaction(fn -> write(record) end) do
          {:atomic, _ok} -> balance
          _ -> elem(record, 3)
        end

      update_rate_limit(user, :increment)
      {:ok, new_balance}
    end

    case get_user_currency(user, attrs.currency) do
      [[], []] ->
        update_rate_limit(user, :increment)
        {:error, :user_does_not_exists}

      [new_currency, []] ->
        calculate_balance.(List.first(new_currency), attrs, :new_deposit)

      [_, [existing_currency]] ->
        calculate_balance.(existing_currency, attrs, :deposit)
    end
  end

  def do_withdraw(user, attrs) do
    update_rate_limit(user, :decrement)

    case get_user_currency(user, attrs.currency) do
      [[], []] ->
        update_rate_limit(user, :increment)
        {:error, :user_does_not_exists}

      [_, [existing_currency]] ->
        [balance, new_record] = prepare_record(existing_currency, attrs, :withdraw)

        if balance < 0 do
          update_rate_limit(user, :increment)
          {:error, :not_enough_money}
        else
          new_balance =
            case transaction(fn -> write(new_record) end) do
              {:atomic, _ok} -> balance
              _ -> elem(existing_currency, 3)
            end

          update_rate_limit(user, :increment)
          {:ok, new_balance}
        end
    end
  end

  def do_get_balance(user, currency) do
    update_rate_limit(user, :decrement)

    case get_user_currency(user, currency) do
      [[], []] ->
        update_rate_limit(user, :increment)
        {:error, :user_does_not_exist}

      [_, [existing_currency]] ->
        update_rate_limit(user, :increment)
        {:ok, elem(existing_currency, 3)}

      [_, []] ->
        update_rate_limit(user, :increment)
        {:ok, 0.00}
    end
  end

  def do_send(attrs) do
    update_rate_limit(attrs.sender, :decrement)
    update_rate_limit(attrs.receiver, :decrement)

    case get_both_users(attrs.sender, attrs.receiver) do
      [_sender, nil] ->
        update_rate_limit(attrs.sender, :increment)
        update_rate_limit(attrs.receiver, :increment)
        {:error, :receiver_does_not_exist}

      [nil, _receiver] ->
        update_rate_limit(attrs.sender, :increment)
        update_rate_limit(attrs.receiver, :increment)
        {:error, :sender_does_not_exist}

      [_sender, _receiver] ->
        {:ok, amount} = do_get_balance(attrs.sender, attrs.currency)

        case amount < attrs.amount do
          true ->
            update_rate_limit(attrs.sender, :increment)
            update_rate_limit(attrs.receiver, :increment)
            {:error, :not_enough_money}

          false ->
            sender_attrs = %{user: attrs.sender, amount: attrs.amount, currency: attrs.currency}

            receiver_attrs = %{
              user: attrs.receiver,
              amount: attrs.amount,
              currency: attrs.currency
            }

            {:ok, sender_bal} = do_withdraw(attrs.sender, sender_attrs)
            {:ok, receiver_bal} = do_deposit(attrs.receiver, receiver_attrs)

            update_rate_limit(attrs.sender, :increment)
            update_rate_limit(attrs.receiver, :increment)
            {:ok, sender_bal, receiver_bal}
        end
    end
  end

  def get_user(user) do
    transaction(fn ->
      index_read(@user, user, :name)
    end)
  end

  def get_rate_limit(user) do
    case transaction(fn -> index_read(@rate_limit, user, :name) end) do
      {:atomic, [{_, _id, _name, limit}]} -> limit
      {:atomic, []} -> 3
    end
  end

  defp update_rate_limit(user, operation)
       when operation in [:increment, :decrement] do
    case transaction(fn -> index_read(@rate_limit, user, :name) end) do
      {:atomic, [{_, id, name, limit}]} ->
        case operation do
          :increment ->
            transaction(fn -> write({@rate_limit, id, name, limit + 1}) end)

          :decrement ->
            transaction(fn -> write({@rate_limit, id, name, limit - 1}) end)
        end

      {:atomic, []} ->
        :ok
    end
  end

  defp get_user_currency(user, currency) do
    {:atomic, new_currency} = transaction(fn -> index_read(@user, user, :name) end)

    {:atomic, existing_currency} =
      transaction(fn -> match_object({@user, :_, user, :_, currency}) end)

    [new_currency, existing_currency]
  end

  defp get_both_users(from_user, to_user) do
    {:atomic, from_user} = transaction(fn -> index_read(@user, from_user, :name) end)

    {:atomic, to_user} = transaction(fn -> index_read(@user, to_user, :name) end)

    [List.first(from_user), List.first(to_user)]
  end

  defp increment_key do
    {:atomic, keys} = transaction(fn -> all_keys(@user) end)

    case List.last(keys) do
      nil -> 1
      id -> id + 1
    end
  end

  defp prepare_record(record, attrs, operation)
       when operation in [:withdraw, :deposit, :new_deposit] do
    [id, new_balance] =
      case operation do
        :new_deposit ->
          [increment_key(), Float.round(attrs.amount, 2)]

        :deposit ->
          [elem(record, 1), Float.round(elem(record, 3) + attrs.amount, 2)]

        :withdraw ->
          [elem(record, 1), Float.round(elem(record, 3) - attrs.amount, 2)]
      end

    [
      new_balance,
      {
        @user,
        id,
        attrs.user,
        new_balance,
        attrs.currency
      }
    ]
  end
end
