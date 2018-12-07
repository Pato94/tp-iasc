defmodule TpIasc.BroadcastQueue do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{messageQueue: [], consumer: nil}, opts)
  end

  def init(_opts) do
    IO.puts("BroadcastQueue started")
    {:ok, _opts}
  end
  
  def push(pid, message) do
	GenServer.cast(pid, {:push, message})
  end
  
  def pop(pid) do
	GenServer.call(pid, :pop)
  end

  def handle_call(:pop, _from, %{messageQueue: [message | mq], consumer: c}) do
    {:reply, message, {messageQueue: mq, consumer: nil}}
  end
  
  def handle_call(:pop, _from, %{messageQueue: [], consumer: c}) do
    {:noreply, %{messageQueue: [], consumer: _from}}
  end

  def handle_cast({:push, message}, %{messageQueue: mq, consumer: nil}) do
    {:noreply, %{messageQueue: mq ++ [message], consumer: nil}}
  end
  
  def handle_cast({:push, message}, %{messageQueue: mq, consumer: c}) do
	send(c, message)
    {:noreply, {messageQueue: mq, consumer: nil}}
  end
end