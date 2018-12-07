defmodule TpIasc.WorkQueue do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{messageQueue: [], subscriberQueue: []}, opts)
  end

  def init(_opts) do
    IO.puts("WorkQueue started")
    {:ok, _opts}
  end
  
  def push(pid, message) do
	GenServer.cast(pid, {:push, message})
  end
  
  def pop(pid) do
	GenServer.call(pid, :pop)
  end

  def handle_call(:pop, _from, %{messageQueue: [], subscriberQueue: sq}) do
    {:noreply, %{messageQueue: [], subscriberQueue: [sq ++ _from]}}
  end
  
  def handle_call(:pop, _from, %{[message | mq], sq}) do
    {:reply, message, %{messageQueue: mq, subscriberQueue: sq}}
  end

  def handle_cast({:push, message}, %{messageQueue: mq, subscriberQueue: []}) do
    {:noreply, %{messageQueue: mq ++ [message], subscriberQueue: []}}
  end
  
  def handle_cast({:push, message}, %{messageQueue: mq, subscriberQueue: [subscriber | sq]}) do
	send(subscriber, message)
    {:reply, %{messageQueue: mq, subscriberQueue: sq}}
  end
end