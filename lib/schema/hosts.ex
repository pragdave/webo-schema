defmodule Schema.Hosts do

  use Schema.Util.Box
  use Agent

  defbox HostEntry,
           name:         String.t,              # the part after the @ sign
           nodes:        [ Schema.Nodes.t ],    # associated with this host
           contact_node: Schema.Node.t         # use this node to get host-level stats


  @me __MODULE__

  @spec start_link(any()) :: {:ok, pid()}
  def start_link(_) do
    { :ok, _pid } = Agent.start_link(fn -> %{} end, name: @me)
  end

  @spec add_node(name :: atom | String.t, type :: Schema.Node.node_type) :: any()
  def add_node(name, type) do
    name = to_string(name)
    { _node_part, host_part } = split_node_name(name)
    node = Schema.Nodes.add_node(name, type, host_part)
     Agent.update(@me, fn hosts -> add_host_and_node(hosts, node, host_part) end)
  end

  @spec remove_node(String.t) :: :ok
  def remove_node(name) do
    Agent.update(@me, fn hosts -> remove_node_and_update_host(hosts, Schema.Nodes.find_by_name(name)) end)
  end


  @spec find_by_name(name :: atom | String.t) :: HostEntry.t | nil
  def find_by_name(name) do
    name = to_string(name)
    Agent.get(@me, fn hosts -> Map.get(hosts, name) end)
  end

  if Mix.env == :test do
    @spec reset() :: :ok
    def reset() do
      Agent.update(@me, fn _ -> %{} end)
    end
  end

  defp split_node_name(name) do
    case String.split(name, "@", parts: 2,  trim: true) do
      [ node ] ->
        { node, "not_active" }
      [ node, host ] ->
        { node, host }
      _other ->
        raise "Can't parse node name: #{inspect name}"
    end
  end

  defp add_host_and_node(hosts, node, host_part) do
    if host = Map.get(hosts, host_part) do
      update_existing_host(hosts, host, node)
    else
      add_new_host(hosts, host_part, node)
    end
  end


  defp remove_node_and_update_host(hosts, nil) do
    hosts
  end

  defp remove_node_and_update_host(hosts, node) do
    Schema.Nodes.remove_node(node.name)
    remove_node_and_update_given_host(hosts, hosts[node.host_name], node)
  end

  @spec remove_node_and_update_given_host([ HostEntry.t ], HostEntry.t | nil, NodeEntry.t) :: any()
  def remove_node_and_update_given_host(hosts, nil, _) do
    hosts  # can't find host
  end

  def remove_node_and_update_given_host(hosts, host, node) do
    IO.inspect host: host
    IO.inspect node: node
    new_host = update_in(host.nodes, fn nodes -> Enum.reject(nodes, fn n -> n.name == node.name end) end)
    IO.inspect new_host: new_host
    cond do
      length(new_host.nodes) == 0 ->
        Map.delete(hosts, new_host.name)
      new_host.contact_node == node ->
        new_host = %{ new_host | contact_node: hd(new_host.nodes) }
        Map.put(hosts, new_host.name, new_host)
      true ->
        Map.put(hosts, new_host.name, new_host)
    end
  end

  defp update_existing_host(hosts, host, node) do
    new_host = update_in(host.nodes, fn nodes -> [ node | nodes ] end)
    Map.put(hosts, host.name, new_host)
  end

  defp add_new_host(hosts, host_part, node) do
    new_host = %HostEntry{ name: host_part, nodes: [ node ], contact_node: node }
    Map.put(hosts, host_part, new_host)
  end

end
