defmodule ExBankingTest do
  use ExUnit.Case
  doctest ExBanking

  test "account creation" do
    assert ExBanking.create_user("Vicky") == :ok
    assert ExBanking.create_user("John") == :ok
    assert ExBanking.create_user("Viji") == :ok
    assert ExBanking.create_user("Rose") == :ok
    assert ExBanking.create_user("vicky") == :ok
    assert ExBanking.create_user("Vicky") == {:error, :user_already_exists}
    assert ExBanking.create_user(1) == {:error, :wrong_arguments}

    assert ExBanking.deposit("Vicky", 1000.50, "USD") == {:ok, 1000.50}
    assert ExBanking.deposit("Vicky", 1000, "USD") == {:ok, 2000.50}
    assert ExBanking.deposit("Vicky", 1000, "EUR") == {:ok, 1000}
    assert ExBanking.deposit("John", 1000, "EUR") == {:ok, 1000}
    assert ExBanking.deposit("John", 1000, "USD") == {:ok, 1000}
    assert ExBanking.deposit("John", 100.55, "INR") == {:ok, 100.55}
    assert ExBanking.deposit("John", -100, "USD") == {:error, :wrong_arguments}
    assert ExBanking.deposit("Jack", 1000, "USD") == {:error, :user_does_not_exist}
    assert ExBanking.deposit("Jack", "1000", "USD") == {:error, :wrong_arguments}
    assert ExBanking.deposit("Jack", 1000, 200) == {:error, :wrong_arguments}
    assert ExBanking.deposit(300, 1000, "USD") == {:error, :wrong_arguments}

    assert ExBanking.withdraw("Vicky", 500, "USD") == {:ok, 1500.50}
    assert ExBanking.withdraw("Vicky", 500.50, "USD") == {:ok, 1000}
    assert ExBanking.withdraw("Vicky", 100, "EUR") == {:ok, 900}
    assert ExBanking.withdraw("John", 100, "EUR") == {:ok, 900}
    assert ExBanking.withdraw("John", 1000, "USD") == {:ok, 0}
    assert ExBanking.withdraw("Jack", 1000, "USD") == {:error, :user_does_not_exist}
    assert ExBanking.withdraw("Jack", "1000", "USD") == {:error, :wrong_arguments}
    assert ExBanking.withdraw("Jack", 1000, 200) == {:error, :wrong_arguments}
    assert ExBanking.withdraw(300, 1000, "USD") == {:error, :wrong_arguments}
    assert ExBanking.withdraw("John", -100, "USD") == {:error, :wrong_arguments}

    assert ExBanking.get_balance("Vicky", "USD") == {:ok, 1000}
    assert ExBanking.get_balance("John", "USD") == {:ok, 0}
    assert ExBanking.get_balance("Vicky", "EUR") == {:ok, 900}
    assert ExBanking.get_balance("John", "EUR") == {:ok, 900}
    assert ExBanking.get_balance("John", "INR") == {:ok, 100.55}
    assert ExBanking.get_balance("Jack", "EUR") == {:error, :user_does_not_exist}
    assert ExBanking.get_balance(15, "USD") == {:error, :wrong_arguments}
    assert ExBanking.get_balance("John", 989) == {:error, :wrong_arguments}

    assert ExBanking.send("Vicky", "John", 100, "USD") == {:ok, 900, 100}
    assert ExBanking.send("Vicky", "John", 800, "USD") == {:ok, 100, 900}
    assert ExBanking.send("Vicky", "John", 1000, "USD") == {:error, :not_enough_money}
    assert ExBanking.send("Vicky", "John", 800, "USD") == {:error, :not_enough_money}
    assert ExBanking.send("Jack", "John", 800, "USD") == {:error, :sender_does_not_exist}
    assert ExBanking.send("Vicky", "Jack", 800, "USD") == {:error, :receiver_does_not_exist}
    assert ExBanking.send("Vicky", "John", -100, "USD") == {:error, :wrong_arguments}
  end
end
