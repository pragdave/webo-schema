defmodule Schema.Nodes do

  use Schema.Util.Box
  use Agent

  @type node_type :: :visible | :hidden | :local

  defbox NodeEntry,
     name:          String.t,
     host_name:     String.t,
     type:          Schema.Nodes.node_type()

  @me __MODULE__

  @spec start_link(any()) :: {:ok, pid()}
  def start_link(_) do
    { :ok, _pid } = Agent.start_link(fn -> %{} end, name: @me)
  end

  @spec add_node(name :: atom | String.t, type :: node_type(), host_name :: String.t) :: any()
  def add_node(name, type, host_name) do
    node = %NodeEntry{ name: to_string(name), host_name: to_string(host_name), type: type }
    Agent.update(@me, fn nodes -> do_add_node(nodes, node) end)
    node
  end

  @spec remove_node(String.t) :: :ok
  def remove_node(name) do
    Agent.update(@me, fn nodes -> Map.delete(nodes, name) end)
  end

  @spec find_by_name(name :: atom | String.t) :: NodeEntry.t | nil
  def find_by_name(name) do
    name = to_string(name)
    Agent.get(@me, fn nodes -> Map.get(nodes, name) end)
  end

  if Mix.env == :test do
    @spec reset() :: :ok
    def reset() do
      Agent.update(@me, fn _ -> %{} end)
    end
  end

  defp do_add_node(nodes, node) do
    Map.put(nodes, node.name, node)
  end

end
