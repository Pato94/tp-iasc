defmodule TpIasc.WorkQueue do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, {[], []}, opts)
  end

  def init({messageQueue, subscriberQueue}) do
    IO.puts("WorkQueue started")
    {:ok, {messageQueue, subscriberQueue}}
  end
  
  def push(pid, message) do
	GenServer.cast(pid, {:push, message})
  end
  
  def pop(pid) do
	GenServer.call(pid, :pop)
  end

  def handle_call(:pop, _from, {[], subscriberQueue}) do
    {:noreply, {[], [subscriberQueue ++ _from]}}
  end
  
  def handle_call(:pop, _from, {[message | messageQueue], subscriberQueue}) do
    {:reply, message, {messageQueue, subscriberQueue}}
  end

  def handle_cast({:push, message}, {messageQueue, []}) do
    {:noreply, {messageQueue ++ [message], []}}
  end
  
  def handle_cast({:push, message}, {messageQueue, [subscriber | subscriberQueue]}) do
	send(subscriber, message)
    {:reply, {messageQueue, subscriberQueue}}
  end
end