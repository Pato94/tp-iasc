defmodule Db.Storage do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{messages: %{}}, name: __MODULE__)
  end

  def init(args) do
    {:ok, args}
  end

  def handle_call({:store, id, message}, _from, state) do
    {:reply, :ok, %{messages: Map.put(state.messages, id, message)}}
  end

  def handle_call({:pop, id}, _from, state) do
    new_state = Map.delete(state.messages, id)
    {:reply, Map.fetch(state.messages, id), %{messages: new_state}}
  end

  # TODO: Delete
  def handle_call(:ack, _from, state) do
    IO.puts "YEAAAHHH"
    {:reply, :ok, state}
  end

  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end
end