defmodule ChannelTest do
  use ExUnit.Case

  test "start_link() creates an unbuffered channel and returns the channel process's PID" do
    assert {:ok, ch} = Channel.start_link
  end

  test "put(ch, item) on an unbuffered channel when there are no takers will block forever" do
    {:ok, ch} = Channel.start_link
    test_process = self
    spawn_link fn ->
      Channel.put(ch, :some_message)
      send test_process, :done
    end
    refute_receive(:done, 50)
  end

  test "take(ch) on an unbuffered channel when there are no putters will block forever" do
    {:ok, ch} = Channel.start_link
    test_process = self
    spawn_link fn ->
      Channel.take(ch)
      send test_process, :done
    end
    refute_receive(:done, 50)
  end

  test "put(ch, item) with a subsequent take(ch) on an unbuffered channel will send the message" do
    {:ok, ch} = Channel.start_link
    test_process = self
    spawn_link fn ->
      send test_process, Channel.put(ch, :some_message)
    end
    :timer.sleep(10)
    assert :some_message = Channel.take(ch)
    assert_receive :ok, 50
  end

  test "take(ch) with a subsequent put(ch, item) on an unbuffered channel will send the message" do
    {:ok, ch} = Channel.start_link
    test_process = self
    spawn_link fn ->
      send test_process, Channel.take(ch)
    end
    :timer.sleep(10)
    assert :ok = Channel.put(ch, :some_message)
    assert_receive :some_message, 50
  end

  test "put(ch, item) on an unbuffered channel will queue up waiting puts" do
    {:ok, ch} = Channel.start_link
    for n <- 1..10 do
      spawn_link(fn -> Channel.put(ch, n) end)
    end
    for n <- 1..10 do
      assert Channel.take(ch) == n
    end
  end

  test "take(ch) on an unbuffered channel will queue up waiting takes" do
    {:ok, ch} = Channel.start_link
    for n <- 1..10 do
      spawn_link(fn -> Channel.take(ch) end)
    end
    for n <- 1..10 do
      assert Channel.put(ch, n) == :ok
    end
  end

  test "start_link(n) creates a channel with a buffer of size n" do
    assert {:ok, ch} = Channel.start_link(10)
  end

  test "put(ch, item) on a buffered channel will return immediately until the buffer is full, then it will block forever" do
    {:ok, ch} = Channel.start_link(3)
    assert :ok = Channel.put(ch, 1)
    assert :ok = Channel.put(ch, 2)
    assert :ok = Channel.put(ch, 3)
    test_process = self
    spawn_link fn ->
      Channel.put(ch, :some_message)
      send test_process, :done
    end
    refute_receive(:done, 50) # we won't actually wait forever in the test
  end

  test "take(ch) on a buffered channel will drain a partially-full buffer, then block forever" do
    {:ok, ch} = Channel.start_link(3)
    Channel.put(ch, 1)
    Channel.put(ch, 2)
    assert Channel.take(ch) == 1
    assert Channel.take(ch) == 2
    test_process = self
    spawn_link fn ->
      Channel.take(ch)
      send test_process, :done
    end
    refute_receive(:done, 50)
  end

  test "take(ch) on a buffered channel with a full buffer and pending puts will drain the buffer and transfer the pending puts to the buffer" do
    {:ok, ch} = Channel.start_link(3)
    for n <- 1..10 do
      spawn_link(fn -> Channel.put(ch, n) end)
    end
    for n <- 1..10 do
      assert Channel.take(ch) == n
    end
  end
end
