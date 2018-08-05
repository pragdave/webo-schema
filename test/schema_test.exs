defmodule SchemaTest do
  use ExUnit.Case
  alias Schema.{ Hosts, Nodes }

  setup do
    Hosts.reset()
    Nodes.reset()
    :ok
  end

  test "adding a node to the hosts adds both tbe host and the node" do
    Hosts.add_node("node@myhost", :visible)

    node = Nodes.find_by_name("node@myhost")

    assert node.name == "node@myhost"

    assert node.host_name == "myhost"

    host = Hosts.find_by_name(node.host_name)

    assert host.name == "myhost"
    assert length(host.nodes) == 1
    assert host.nodes == [ node ]
  end

  test "adding a node to the hosts makes it the contact node for that host" do
    Hosts.add_node("node1@myhost", :visible)

    node = Nodes.find_by_name("node1@myhost")
    host = Hosts.find_by_name(node.host_name)

    assert host.name == "myhost"
    assert length(host.nodes) == 1
    assert host.nodes == [ node ]
  end

  test "adding two nodes on the same host" do
    Hosts.add_node("node1@myhost", :visible)
    Hosts.add_node("node2@myhost", :visible)

    node1 = Nodes.find_by_name("node1@myhost")
    node2 = Nodes.find_by_name("node2@myhost")

    host1 = Hosts.find_by_name(node1.host_name)
    host2 = Hosts.find_by_name(node2.host_name)

    assert host1 == host2

    assert host1.name == "myhost"
    assert length(host1.nodes) == 2
    assert node1 in host1.nodes
    assert node2 in host1.nodes
  end

  test "adding two nodes on different hosts" do
    Hosts.add_node("node1@myhost1", :visible)
    Hosts.add_node("node2@myhost2", :visible)

    node1 = Nodes.find_by_name("node1@myhost1")
    node2 = Nodes.find_by_name("node2@myhost2")

    host1 = Hosts.find_by_name(node1.host_name)
    host2 = Hosts.find_by_name(node2.host_name)

    assert host1 != host2

    assert host1.name == "myhost1"
    assert length(host1.nodes) == 1
    assert node1 in host1.nodes

    assert host2.name == "myhost2"
    assert length(host2.nodes) == 1
    assert node2 in host2.nodes
  end

  test "deleting a node removes it" do
    Hosts.add_node("node1@myhost", :visible)
    Hosts.add_node("node2@myhost", :visible)

    node1 = Nodes.find_by_name("node1@myhost")
    node2 = Nodes.find_by_name("node2@myhost")

    host1 = Hosts.find_by_name(node1.host_name)
    host2 = Hosts.find_by_name(node2.host_name)

    assert host1 == host2

    assert length(host1.nodes) == 2
    assert node1 in host1.nodes
    assert node2 in host1.nodes
    assert host1.contact_node == node1

    Hosts.remove_node(node2.name)
    host1 = Hosts.find_by_name(node1.host_name)

    assert Nodes.find_by_name(node2.name) == nil
    assert length(host1.nodes) == 1
    assert node1 in host1.nodes
    assert host1.contact_node == node1
  end

  test "deleting the contact node when other nodes are present updates the contact node" do
    Hosts.add_node("node1@myhost", :visible)
    Hosts.add_node("node2@myhost", :visible)

    node1 = Nodes.find_by_name("node1@myhost")
    node2 = Nodes.find_by_name("node2@myhost")
    host1 = Hosts.find_by_name(node1.host_name)

    assert length(host1.nodes) == 2
    assert host1.contact_node == node1

    Hosts.remove_node(node1.name)
    host1 = Hosts.find_by_name(node2.host_name)

    assert length(host1.nodes) == 1
    assert node2 in host1.nodes
    assert host1.contact_node == node2
  end

  test "deleting the last node removes the host" do
    Hosts.add_node("node1@myhost", :visible)
    Hosts.add_node("node2@myhost", :visible)

    node1 = Nodes.find_by_name("node1@myhost")
    node2 = Nodes.find_by_name("node2@myhost")

    host = Hosts.find_by_name(node1.host_name)
    assert length(host.nodes) == 2
    assert node1 in host.nodes
    assert node2 in host.nodes
    assert host.contact_node == node1

    Hosts.remove_node(node1.name)
    host = Hosts.find_by_name("myhost")
    assert length(host.nodes) == 1
    assert node2 in host.nodes
    assert host.contact_node == node2

    Hosts.remove_node(node2.name)
    assert Hosts.find_by_name("myhost") == nil
  end



end
