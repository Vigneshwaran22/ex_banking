defmodule ExBanking do
  use GenServer

  def start(_type, _args) do
    IO.puts("********ExBanking App Started*****")
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_args), do: {:ok, %{}}

  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) when is_binary(user) do
    GenServer.call(__MODULE__, {:create_user, user})
  end

  def create_user(_), do: {:error, :wrong_arguments}

  def handle_call({:create_user, user}, _from, state) do
    case Map.has_key?(state, user) do
      true ->
        {:reply, {:error, :user_already_exists}, state}

      _ ->
        state = Map.put_new(state, user, %{})
        {:reply, :ok, state}
    end
  end

  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def get_balance(user, currency) when is_binary(user) and is_binary(currency) do
    GenServer.call(__MODULE__, {:balance, user, currency})
  end

  def get_balance(_user, _currency), do: {:error, :wrong_arguments}

  def handle_call({:balance, user, currency}, _from, state) do
    cond do
      user_exist(user, state) == false ->
        {:reply, {:error, :user_does_not_exist}, state}

      account_exist(user, currency, state) == false ->
        {:reply, {:ok, 0}, state}

      true ->
        {:reply, {:ok, user_account(user, currency, state)}, state}
    end
  end

  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def deposit(user, amount, currency)
      when is_binary(user) and is_number(amount) and is_binary(currency) and amount >= 0 do
    GenServer.call(__MODULE__, {:deposit, user, currency, amount})
  end

  def deposit(_, _, _), do: {:error, :wrong_arguments}

  def handle_call({:deposit, user, currency, amount}, _from, state) do
    cond do
      user_exist(user, state) == false ->
        {:reply, {:error, :user_does_not_exist}, state}

      account_exist(user, currency, state) == false ->
        accounts = user_accounts(user, state) |> Map.put_new(currency, amount)
        state = update_state(state, user, accounts)
        {:reply, {:ok, amount}, state}

      true ->
        balance = user_account(user, currency, state) + amount
        accounts = user_accounts(user, state) |> Map.put(currency, balance)
        state = update_state(state, user, accounts)
        {:reply, {:ok, balance}, state}
    end
  end

  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error,
             :wrong_arguments
             | :user_does_not_exist
             | :not_enough_money
             | :too_many_requests_to_user}
  def withdraw(user, amount, currency)
      when is_binary(user) and is_number(amount) and is_binary(currency) and amount >= 0 do
    GenServer.call(__MODULE__, {:withdraw, user, currency, amount})
  end

  def withdraw(_, _, _), do: {:error, :wrong_arguments}

  def handle_call({:withdraw, user, currency, amount}, _from, state) do
    cond do
      user_exist(user, state) == false ->
        {:reply, {:error, :user_does_not_exist}, state}

      account_exist(user, currency, state) == false ->
        {:reply, {:error, :not_enough_money}, state}

      user_account(user, currency, state) < amount ->
        {:reply, {:error, :not_enough_money}, state}

      true ->
        balance = user_account(user, currency, state) - amount
        accounts = user_accounts(user, state) |> Map.put(currency, balance)
        state = update_state(state, user, accounts)
        {:reply, {:ok, balance}, state}
    end
  end

  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) ::
          {:ok, from_user_balance :: number, to_user_balance :: number}
          | {:error,
             :wrong_arguments
             | :not_enough_money
             | :sender_does_not_exist
             | :receiver_does_not_exist
             | :too_many_requests_to_sender
             | :too_many_requests_to_receiver}
  def send(from_user, to_user, amount, currency)
      when is_binary(from_user) and is_binary(to_user) and is_number(amount) and
             is_binary(currency) and amount >= 0 do
    GenServer.call(__MODULE__, {:send, from_user, to_user, currency, amount})
  end

  def send(_, _, _, _), do: {:error, :wrong_arguments}

  def handle_call({:send, from_user, to_user, currency, amount}, _from, state) do
    cond do
      user_exist(from_user, state) == false ->
        {:reply, {:error, :sender_does_not_exist}, state}

      user_exist(to_user, state) == false ->
        {:reply, {:error, :receiver_does_not_exist}, state}

      account_exist(from_user, currency, state) == false ->
        {:reply, {:error, :not_enough_money}, state}

      user_account(from_user, currency, state) < amount ->
        {:reply, {:error, :not_enough_money}, state}

      true ->
        cond do
          account_exist(to_user, currency, state) == false ->
            accounts = user_accounts(to_user, state) |> Map.put_new(currency, amount)
            state = update_state(state, to_user, accounts)
            sender_balnce = user_account(from_user, currency, state)
            balance = sender_balnce - amount
            accounts = user_accounts(from_user, state) |> Map.put(currency, balance)
            state = update_state(state, from_user, accounts)
            {:reply, {:ok, balance, amount}, state}

          true ->
            receiver_balance = user_account(to_user, currency, state) + amount
            sender_balance = user_account(from_user, currency, state) - amount

            receiver_accounts =
              user_accounts(to_user, state) |> Map.put(currency, receiver_balance)

            sender_accounts = user_accounts(from_user, state) |> Map.put(currency, sender_balance)

            state =
              update_state(state, to_user, receiver_accounts)
              |> update_state(from_user, sender_accounts)

            {:reply, {:ok, sender_balance, receiver_balance}, state}
        end
    end
  end

  def user_exist(user, state), do: Map.has_key?(state, user)

  def user_accounts(user, state), do: Map.get(state, user)

  def account_exist(user, currency, state),
    do: user_accounts(user, state) |> Map.has_key?(currency)

  def user_account(user, currency, state), do: user_accounts(user, state) |> Map.get(currency)

  def update_state(state, user, accounts) do
    Map.put(state, user, accounts)
  end
end
