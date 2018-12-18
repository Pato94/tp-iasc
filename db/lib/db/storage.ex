defmodule Db.Storage do
  use GenServer
  require Logger

  def start_link(opts) do
    Logger.debug "Started Db.Storage"
    GenServer.start_link(__MODULE__, %{messages: %{}}, name: __MODULE__)
  end

  def init(args) do
    {:ok, args}
  end

  def handle_call({:store, id, message}, _from, state) do
    Logger.debug "Storage :store called, id: #{id}, message: #{message}"
    {:reply, :ok, %{messages: Map.put(state.messages, id, message)}}
  end

  def handle_call({:pop, id}, _from, state) do
    new_state = Map.delete(state.messages, id)
    {:ok, message} = Map.fetch(state.messages, id)
    Logger.debug "Storage :pop called, id: #{id}, message: #{message}"
    {:reply, message, %{messages: new_state}}
  end

  def handle_call(:ack, _from, state) do
    Logger.debug "ACK received from master"
    {:reply, :ok, state}
  end

  def handle_call(_msg, _from, state) do
    Logger.debug "Storage unknown call received"
    {:reply, :ok, state}
  end

  def handle_cast(_msg, state) do
    Logger.debug "Storage unknown cast received"
    {:noreply, state}
  end
end