defmodule Api.SocketConsumer do
  use GenServer
  require Logger

  def start_link(opts = [socket: socket]) do
    GenServer.start_link(__MODULE__, %{socket: socket}, opts)
  end

  def init(args) do
    {:ok, args}
  end

  def handle_cast({:consume, from, message}, state = %{socket: socket}) do
    Phoenix.Channel.push(socket, "new_msg", %{body: message})
    # TODO: Delay?
    GenServer.cast(from, {:subscribe, self()})
    {:noreply, state}
  end

  def handle_cast(_msg, state) do
    Logger.debug "SocketConsumer: Unknown cast"
    {:noreply, state}
  end

  def handle_call(_msg, _from, state) do
    Logger.debug "SocketConsumer: Unknown call"
    {:reply, :ok, state}
  end

  def subscribe(server, queue) do
    GenServer.cast(queue, {:subscribe, server})
  end
end