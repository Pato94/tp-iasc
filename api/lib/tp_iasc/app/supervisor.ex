defmodule TpIasc.Supervisor do
  use Supervisor

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg)
  end

  def init(arg) do
    children = [
      {TpIasc.Registry, name: TpIasc.Registry},
      {DynamicSupervisor, name: TpIasc.QueueSupervisor, strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  def create_broadcast_queue do
    {:ok, queue} = DynamicSupervisor.start_child(TpIasc.QueueSupervisor, TpIasc.BroadcastQueue)
    TpIasc.Registry.store_new(TpIasc.Registry, queue)
  end

  def create_worker_queue do
    {:ok, queue} = DynamicSupervisor.start_child(TpIasc.QueueSupervisor, TpIasc.WorkQueue)
    TpIasc.Registry.store_new(TpIasc.Registry, queue)
  end

  def get_queue(id) do
    TpIasc.Registry.get_queue(TpIasc.Registry, id)
  end
end