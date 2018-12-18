defmodule Api.Supervisor do
  use Supervisor

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg)
  end

  def init(arg) do
    children = [
      {Api.Registry, name: Api.Registry},
      {DynamicSupervisor, name: Api.QueueSupervisor, strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  def create_broadcast_queue(id) do
    {:ok, queue} = DynamicSupervisor.start_child(Api.QueueSupervisor, {Api.BroadcastQueue, id: id})
    queue
  end

  def create_worker_queue(id) do
    {:ok, queue} = DynamicSupervisor.start_child(Api.QueueSupervisor, {Api.WorkQueue, id: id})
    queue
  end

  def get_queue(id) do
    Api.Registry.get_queue(Api.Registry, id)
  end
end