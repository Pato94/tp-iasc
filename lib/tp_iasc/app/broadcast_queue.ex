defmodule TpIasc.BroadcastQueue do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, {[], nil}, opts)
  end

  def init({messageQueue, consumer}) do
    IO.puts("BroadcastQueue started")
    {:ok, {messageQueue, consumer}}
  end
  
  def push(pid, message) do
	GenServer.cast(pid, {:push, message})
  end
  
  def pop(pid) do
	GenServer.call(pid, :pop)
  end

  def handle_call(:pop, _from, {[message | messageQueue], consumer}) do
    {:reply, message, {messageQueue, nil}}
  end
  
  def handle_call(:pop, _from, {[], consumer}) do
    {:noreply, {[], _from}}
  end

  def handle_cast({:push, message}, {messageQueue, nil}) do
    {:noreply, {messageQueue ++ [message], nil}}
  end
  
  def handle_cast({:push, message}, {messageQueue, consumer}) do
	send(consumer, message)
    {:noreply, {messageQueue, nil}}
  end
end