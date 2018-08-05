defmodule Schema.Application do

  use Application

  def start(_type, _args) do
    children = [
      Schema.Hosts,
      Schema.Nodes,
    ]

    opts = [strategy: :one_for_one, name: Schema.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
