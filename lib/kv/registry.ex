defmodule KV.Registry do
  use GenServer

  ## CLIENTE

  def start_link(opts) do
    GenServer.start_link(KV.Registry, :ok, opts)
  end

  def lookup(name) do
    GenServer.call(__MODULE__, {:lookup, name})
  end

  def create(name) do
    GenServer.cast(__MODULE__, {:create, name})
  end

  # SERVIDOR 

  @impl true
  def init(:ok) do
    {:ok, {%{}, %{}}}
  end

  @impl true
  def handle_call({:lookup, name}, _from, {names, refs}) do
    {:reply, Map.fetch(names, name), {names, refs}}
  end

  @impl true
  def handle_cast({:create, name}, {names, refs}) do
    if Map.has_key?(names, name) do
      {:noreply, {names, refs}}
    else
      {:ok, bucket} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV)
      ref = Process.monitor(bucket)
      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, bucket)
      {:noreply, {names, refs}}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    names = Map.delete(names, name)
    {:noreply, {names, refs}}
  end

  @impl true
  def handle_info(msg, state) do
    require Logger
    Logger.debug("Não Conheço essa mensagem: #{inspect(msg)}")
    {:noreply, state}
  end
end
