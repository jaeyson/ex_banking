# ExBanking

[//]: # "Badges"
[![Actions Status][actions badge]][actions]

[//]: # "Links"
[actions]: https://github.com/jaeyson/ex_banking/actions

[//]: # "Image sources"
[actions badge]: https://github.com/jaeyson/ex_banking/actions/workflows/ci.yml/badge.svg

`using-task-module` branch: using GenServer + Task

To simulate local nodes talking to each other and making transactions:

```elixir
# node1
# iex --sname node1@localhost -S mix

# then add users
iex> ExBanking.create_user("test")
:ok

iex> ExBanking.deposit("test", 1.2589, "usd")
{:ok, 1.26}
```

Then another node connects:

```elixir
# node2 (new)
# iex --sname node2@localhost -S mix

# connects to node1
iex> State.connect_node(:node1@localhost)

iex> ExBanking.create_user("node2")
:ok

iex> ExBanking.deposit("node2", 10, "usd")
{:ok, 10.0}

iex> ExBanking.send("node2", "test", 10, "usd")
{:ok 0.0, 11.26}

iex> ExBanking.get_balance("test", "usd")
{:ok, 11.26}

iex> ExBanking.get_balance("node2", "usd")
{:ok, 0.0}
```
