defmodule Channel.BoundedQueueText do
  use ExUnit.Case
  alias Channel.BoundedQueue, as: BQ

  test "new" do
    assert q = BQ.new(3)
  end

  test "put" do
    q = BQ.new(2)
    assert {:ok, q2} = BQ.put(q, "item1")
    assert {:ok, q3} = BQ.put(q2, "item2")
    assert {:full, ^q3} = BQ.put(q3, "item3")
  end

  test "take" do
    q = BQ.new(2)
    {:ok, q2} = BQ.put(q, "item1")
    {:ok, q3} = BQ.put(q2, "item2")
    assert {{:value, "item1"}, q4} = BQ.take(q3)
    assert {{:value, "item2"}, q5} = BQ.take(q4)
    assert {:empty, ^q5} = BQ.take(q5)
  end
end
