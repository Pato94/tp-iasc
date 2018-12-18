defmodule Api.BroadcastQueue do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  def init(args) do
    Logger.debug "BroadcastQueue started"
    {:ok, args}
  end

  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  def handle_cast({:subscribe, pid}, state) do
    subscriberQueue = state[pid]
    if subscriberQueue do
      GenServer.cast(subscriberQueue, {:subscribe, pid})
      {:noreply, state}
    else
      id = Api.Registry.new_worker_queue(Api.Registry)
      newState = Map.put(state, pid, id)
      GenServer.cast(id, {:subscribe, pid})
      {:noreply, newState}
    end
  end

  def handle_cast({:process, message}, state) do
    for {_, v} <- state do
      GenServer.cast(v, {:process, message})
    end
    {:noreply, state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end
end