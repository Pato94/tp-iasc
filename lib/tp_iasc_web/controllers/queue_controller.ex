defmodule TpIascWeb.QueueController do
  use TpIascWeb, :controller

  def create(conn, params) do
    broadcast = Map.get(params, "broadcast", false)

    conn
    |> put_status(:created)
    |> text("[LIE!] Queue created, broadcast: #{broadcast}!")
  end
end
