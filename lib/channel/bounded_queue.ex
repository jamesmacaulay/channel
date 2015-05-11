defmodule Channel.BoundedQueue do
  def new(max_size) do
    {Channel.BoundedQueue, :queue.new, 0, max_size}
  end

  def put(bounded_queue, item) do
    {Channel.BoundedQueue, queue, len, max} = bounded_queue
    if len == max do
      {:full, bounded_queue}
    else
      {:ok, {Channel.BoundedQueue, :queue.in(item, queue), len + 1, max}}
    end
  end
  
  def take(bounded_queue) do
    {Channel.BoundedQueue, queue, len, max} = bounded_queue
    if len == 0 do
      {:empty, bounded_queue}
    else
      {{:value, item}, new_queue} = :queue.out(queue)
      {{:value, item}, {Channel.BoundedQueue, new_queue, len - 1, max}}
    end
  end
end
