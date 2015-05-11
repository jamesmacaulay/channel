defmodule Channel.Server do
  use GenServer
  alias Channel.BoundedQueue

  @max_queue_size 1024

  def new(buffer) do
    {BoundedQueue.new(@max_queue_size), buffer, BoundedQueue.new(@max_queue_size)}
  end

  def init([]) do
    {:ok, new(:unbuffered)}
  end
  
  def init([buffer_size]) do
    if buffer_size <= 0 do
      {:ok, new(:unbuffered)}
    else
      {:ok, new(BoundedQueue.new(buffer_size))}
    end
  end

  def handle_call(:take, taker, {takes, :unbuffered, puts}) do
    case BoundedQueue.take(puts) do
      {{:value, {item, putter}}, puts} ->
        GenServer.reply(taker, item)
        GenServer.reply(putter, :ok)
        {:noreply, {takes, :unbuffered, puts}}
      {:empty, _} ->
        {:ok, takes} = BoundedQueue.put(takes, taker)
        {:noreply, {takes, :unbuffered, puts}}
    end
  end

  def handle_call(:take, taker, {takes, buffer, puts}) do
    case BoundedQueue.take(buffer) do
      {{:value, buffer_item}, buffer} ->
        case BoundedQueue.take(puts) do
          {{:value, {puts_item, putter}}, puts} ->
            GenServer.reply(taker, buffer_item)
            GenServer.reply(putter, :ok)
            {:ok, buffer} = BoundedQueue.put(buffer, puts_item)
            {:noreply, {takes, buffer, puts}}
          {:empty, _} ->
            {:reply, buffer_item, {takes, buffer, puts}}
        end
      {:empty, _} ->
        {:ok, takes} = BoundedQueue.put(takes, taker)
        {:noreply, {takes, buffer, puts}}
    end
  end

  def handle_call({:put, item}, putter, {takes, :unbuffered, puts}) do
    case BoundedQueue.take(takes) do
      {{:value, taker}, takes} ->
        GenServer.reply(taker, item)
        {:reply, :ok, {takes, :unbuffered, puts}}
      {:empty, _} ->
        {:ok, puts} = BoundedQueue.put(puts, {item, putter})
        {:noreply, {takes, :unbuffered, puts}}
    end
  end

  def handle_call({:put, item}, putter, {takes, buffer, puts}) do
    case BoundedQueue.take(takes) do
      {{:value, taker}, takes} ->
        GenServer.reply(taker, item)
        {:reply, :ok, {takes, buffer, puts}}
      {:empty, _} ->
        case BoundedQueue.put(buffer, item) do
          {:ok, buffer} ->
            {:reply, :ok, {takes, buffer, puts}}
          {:full, _} ->
            {:ok, puts} = BoundedQueue.put(puts, {item, putter})
            {:noreply, {takes, buffer, puts}}
        end
    end
  end
end
