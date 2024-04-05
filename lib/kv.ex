defmodule KV do
  use Agent

  def start_link(opts) do
    Agent.start_link(fn -> %{} end, opts)
  end

  def append(pid, key, value) do
    Agent.update(pid, fn kv ->
      Map.update(kv, key, kv[key], fn values ->
        [value | values]
      end)
    end)
  end

  def put(pid, key, value) do
    Agent.update(pid, fn kv ->
      Map.put(kv, key, value)
    end)
  end

  def update(pid, key, value) do
    Agent.update(pid, fn kv ->
      Map.update!(kv, key, fn _ -> value end)
    end)
  end

  def get(pid, key) do
    Agent.get(pid, fn kv -> kv[key] end)
  end

  def delete(pid, key) do
    Agent.update(pid, &Map.pop(&1, key))
  end
end
