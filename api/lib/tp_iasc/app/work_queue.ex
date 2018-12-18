defmodule TpIasc.WorkQueue do
  use GenServer
  require HTTPoison
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  def init(_opts) do
    IO.puts("WorkQueue started")
    {:ok, %{}}
  end

  def handle_call({:push, id, message}, _from, state) do
    response = TpIasc.DbClient.push(id, message)
    {:reply, :ok, state}
  end

  def handle_call({:pop, id}, _from, state) do
    %{"message" => message} = TpIasc.DbClient.pop(id)
    {:reply, message, state}
  end

  def handle_call(_msg, _from, state) do
    Logger.debug "WorkQueue: unknown call received"
    {:reply, :ok, state}
  end

  def handle_cast(_msg, state) do
    Logger.debug "WorkQueue: unknown cast received"
    {:noreply, state}
  end
end