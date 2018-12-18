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
    Logger.debug "BroadcastQueue unknown call called"
    {:reply, :ok, state}
  end

  def handle_cast({:subscribe, pid}, state) do
    Logger.debug "BroadcastQueue subscribe called #{inspect(pid)}"
    subscriberQueue = state[pid]
    if subscriberQueue do
      GenServer.cast(subscriberQueue, {:subscribe, pid})
      {:noreply, state}
    else
      id = Api.Registry.new_worker_queue(Api.Registry)
      {:ok, queue} = Api.Registry.get_queue(Api.Registry, id)
      newState = Map.put(state, pid, queue)
      GenServer.cast(queue, {:subscribe, pid})
      {:noreply, newState}
    end
  end

  def handle_cast({:process, message}, state) do
    Logger.debug "BroadcastQueue process called #{message}"
    for {_, v} <- state do
      GenServer.cast(v, {:process, message})
    end
    {:noreply, state}
  end

  def handle_cast(_msg, state) do
    Logger.debug "BroadcastQueue unknown cast"
    {:noreply, state}
  end
end