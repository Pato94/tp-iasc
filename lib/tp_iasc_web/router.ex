defmodule TpIascWeb.Router do
  use TpIascWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", TpIascWeb do
    pipe_through :api
  end
end
