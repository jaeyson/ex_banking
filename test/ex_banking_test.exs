defmodule ExBankingTest do
  use ExUnit.Case
  # doctest ExBanking

  import Mox

  setup :verify_on_exit!

  test "wrong placing of arguments" do
    ExBankingBehaviourMock
    |> expect(:deposit, fn currency, name, amount ->
      assert name == "Nobody"
      assert amount == 10
      assert currency == "usd"
      {:error, :wrong_arguments}
    end)

    assert Bound.deposit("usd", "Nobody", 10) === {:error, :wrong_arguments}
  end

  describe "create_user/1" do
    test "Creates user and saves to ram" do
      ExBankingBehaviourMock
      |> expect(:create_user, fn args ->
        assert args == "John Smith"
        :ok
      end)

      assert Bound.create_user("John Smith") === :ok
    end

    test "throws error when user is already created" do
      ExBankingBehaviourMock
      |> expect(:create_user, fn args ->
        assert args == "John Smith"
        :ok
      end)
      |> expect(:create_user, fn args ->
        assert args == "John Smith"
        {:error, :user_already_exists}
      end)

      assert Bound.create_user("John Smith") === :ok
      assert Bound.create_user("John Smith") === {:error, :user_already_exists}
    end
  end

  describe "deposit/3" do
    test "deposits amount on existing user" do
      ExBankingBehaviourMock
      |> expect(:create_user, fn args ->
        assert args == "John Smith"
        :ok
      end)
      |> expect(:deposit, fn name, amount, currency ->
        assert name == "John Smith"
        assert amount == 10.28561
        assert currency == "usd"
        {:ok, 10.29}
      end)

      assert Bound.create_user("John Smith") === :ok
      assert Bound.deposit("John Smith", 10.28561, "usd") === {:ok, 10.29}
    end

    test "deposits amount on non-existing user" do
      ExBankingBehaviourMock
      |> expect(:deposit, fn name, amount, currency ->
        assert name == "Nobody"
        assert amount == 10
        assert currency == "usd"
        {:error, :user_does_not_exist}
      end)

      assert Bound.deposit("Nobody", 10, "usd") ===
               {:error, :user_does_not_exist}
    end
  end

  describe "withdraw/3" do
    test "withdraw enough amount" do
      ExBankingBehaviourMock
      |> expect(:create_user, fn args ->
        assert args == "John Smith"
        :ok
      end)
      |> expect(:deposit, fn name, amount, currency ->
        assert name == "John Smith"
        assert amount == 10
        assert currency == "usd"
        {:ok, 10.0}
      end)
      |> expect(:withdraw, fn name, amount, currency ->
        assert name == "John Smith"
        assert amount == 10
        assert currency == "usd"
        {:ok, 0.0}
      end)

      assert Bound.create_user("John Smith") === :ok
      assert Bound.deposit("John Smith", 10, "usd") === {:ok, 10.0}
      assert Bound.withdraw("John Smith", 10, "usd") === {:ok, 0.0}
    end

    test "withdraw exceeding amount" do
      ExBankingBehaviourMock
      |> expect(:create_user, fn args ->
        assert args == "John Smith"
        :ok
      end)
      |> expect(:deposit, fn name, amount, currency ->
        assert name == "John Smith"
        assert amount == 10
        assert currency == "usd"
        {:ok, 10.0}
      end)
      |> expect(:withdraw, fn name, amount, currency ->
        assert name == "John Smith"
        assert amount == 100
        assert currency == "usd"
        {:error, :not_enough_money}
      end)

      assert Bound.create_user("John Smith") === :ok
      assert Bound.deposit("John Smith", 10, "usd") === {:ok, 10.0}
      assert Bound.withdraw("John Smith", 100, "usd") === {:error, :not_enough_money}
    end

    test "withdraw on non-existing user" do
      ExBankingBehaviourMock
      |> expect(:withdraw, fn name, amount, currency ->
        assert name == "Nobody"
        assert amount == 100
        assert currency == "usd"
        {:error, :user_does_not_exist}
      end)

      assert Bound.withdraw("Nobody", 100, "usd") === {:error, :user_does_not_exist}
    end
  end

  describe "get_balance/3" do
    test "get balance from existing user" do
      ExBankingBehaviourMock
      |> expect(:create_user, fn args ->
        assert args == "John Smith"
        :ok
      end)
      |> expect(:deposit, fn name, amount, currency ->
        assert name == "John Smith"
        assert amount == 10
        assert currency == "usd"
        {:ok, 10.0}
      end)
      |> expect(:get_balance, fn name, currency ->
        assert name == "John Smith"
        assert currency == "usd"
        {:ok, 10.0}
      end)

      assert Bound.create_user("John Smith") === :ok
      assert Bound.deposit("John Smith", 10, "usd") === {:ok, 10.0}
      assert Bound.get_balance("John Smith", "usd") === {:ok, 10.0}
    end

    test "get balance from non-existing user" do
      ExBankingBehaviourMock
      |> expect(:get_balance, fn name, currency ->
        assert name == "Nobody"
        assert currency == "usd"
        {:error, :user_does_not_exist}
      end)

      assert Bound.get_balance("Nobody", "usd") === {:error, :user_does_not_exist}
    end
  end

  describe "send/4" do
    test "send to another user" do
      ExBankingBehaviourMock
      |> expect(:create_user, fn args ->
        assert args == "John Smith"
        :ok
      end)
      |> expect(:create_user, fn args ->
        assert args == "Jane Smith"
        :ok
      end)
      |> expect(:deposit, fn name, amount, currency ->
        assert name == "John Smith"
        assert amount == 10
        assert currency == "usd"
        {:ok, 10.0}
      end)
      |> expect(:send, fn sender, receiver, amount, currency ->
        assert sender == "John Smith"
        assert receiver == "Jane Smith"
        assert amount == 10
        assert currency == "usd"
        {:ok, 0.0, 10.0}
      end)

      assert Bound.create_user("John Smith") === :ok
      assert Bound.create_user("Jane Smith") === :ok
      assert Bound.deposit("John Smith", 10, "usd") === {:ok, 10.0}
      assert Bound.send("John Smith", "Jane Smith", 10, "usd") === {:ok, 0.0, 10.0}
    end

    test "non-existing sender sending to another user" do
      ExBankingBehaviourMock
      |> expect(:create_user, fn args ->
        assert args == "Jane Smith"
        :ok
      end)
      |> expect(:send, fn sender, receiver, amount, currency ->
        assert sender == "John Smith"
        assert receiver == "Jane Smith"
        assert amount == 10
        assert currency == "usd"
        {:error, :sender_does_not_exist}
      end)

      assert Bound.create_user("Jane Smith") === :ok
      assert Bound.send("John Smith", "Jane Smith", 10, "usd") === {:error, :sender_does_not_exist}
    end

    test "send to non-existing receiver" do
      ExBankingBehaviourMock
      |> expect(:create_user, fn args ->
        assert args == "John Smith"
        :ok
      end)
      |> expect(:deposit, fn name, amount, currency ->
        assert name == "John Smith"
        assert amount == 10
        assert currency == "usd"
        {:ok, 10.0}
      end)
      |> expect(:send, fn sender, receiver, amount, currency ->
        assert sender == "John Smith"
        assert receiver == "Jane Smith"
        assert amount == 10
        assert currency == "usd"
        {:ok, :receiver_does_not_exist}
      end)

      assert Bound.create_user("John Smith") === :ok
      assert Bound.deposit("John Smith", 10, "usd") === {:ok, 10.0}
      assert Bound.send("John Smith", "Jane Smith", 10, "usd") === {:ok, :receiver_does_not_exist}
    end

    test "not enough money to send" do
      ExBankingBehaviourMock
      |> expect(:create_user, fn args ->
        assert args == "John Smith"
        :ok
      end)
      |> expect(:create_user, fn args ->
        assert args == "Jane Smith"
        :ok
      end)
      |> expect(:deposit, fn name, amount, currency ->
        assert name == "John Smith"
        assert amount == 10
        assert currency == "usd"
        {:ok, 10.0}
      end)
      |> expect(:send, fn sender, receiver, amount, currency ->
        assert sender == "John Smith"
        assert receiver == "Jane Smith"
        assert amount == 100
        assert currency == "usd"
        {:error, :not_enough_money}
      end)

      assert Bound.create_user("John Smith") === :ok
      assert Bound.create_user("Jane Smith") === :ok
      assert Bound.deposit("John Smith", 10, "usd") === {:ok, 10.0}
      assert Bound.send("John Smith", "Jane Smith", 100, "usd") === {:error, :not_enough_money}
    end
  end
end
