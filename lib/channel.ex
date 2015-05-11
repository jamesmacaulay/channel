defmodule Channel do
  use GenServer
  
  def start_link do
    start_link(0)
  end

  def start_link(buffer_size) do
    GenServer.start_link(Channel.Server, [buffer_size])
  end
  
  def put(channel_pid, item) do
    GenServer.call(channel_pid, {:put, item}, :infinity)
  end

  def take(channel_pid) do
    GenServer.call(channel_pid, :take, :infinity)
  end
end
