defmodule KV.Registry do
  use GenServer

  ## CLIENTE

  def start_link(opts) do
    GenServer.start_link(KV.Registry, :ok, opts)
    #inicia um processo genserver linkado ao processo atual
  end

  def lookup(name) do
    GenServer.call(__MODULE__, {:lookup, name})
    #faz uma chamada síncrona ao servidor e espera uma resposta
  end

  def create(name) do
    GenServer.cast(__MODULE__, {:create, name})
    #faz uma solicitação ao servidor sem esperar resposta
  end

  # SERVIDOR

  @impl true
  def init(:ok) do
    #invocado quando o servidor inicia, start e start_link só funcionam depois que
    #essa função tiver seu retorno
    {:ok, {%{}, %{}}}
  end

  @impl true
  def handle_call({:lookup, name}, _from, {names, refs}) do
    #usamos esta função para que ela opere sobre as chamadas de lookup ou melhor, .call
    #call fica "bloqueado" até que tenha uma resposta da função handle call

    {:reply, Map.fetch(names, name), {names, refs}}
    |>IO.inspect()
    #retorna :reply, {:ok, pid}, {%{names, buckets/pids}, %{refs/monitoramento do pid, names}}
  end

  @impl true
  def handle_cast({:create, name}, {names, refs}) do
    #função usada para lidar com as chamadas assync de create/cast
    if Map.has_key?(names, name) do
      {:noreply, {names, refs}}
       #se o mapa tiver a chave, nada é feito e somente é retornado o mapa de nomes e refs
    else
      #caso nao tenha a chave no mapa de names, é incializado um supervisor dinamico
      #que vai receber os modulos bucket supervisor e o modulo KV
      #criamos uma variavel ref que monitora o nosso PID/bucket
      #com esse monitoramento podemos ter conhecimento se o processo ainda está vivo
      #além de termos algumas outras espeficiações, que realmente são referencias
      #após isso inserimos essa ref dentro de um mapa de refs, ou seja, mapa de monitoramento de buckets/PIDs
      #cada ref é a chave de um valor que é o nome do bucket/PID
      #por fim, criamos um mapa de names que recebe o name como chave e o bucket/PID como valor
      #ao final retornamos uma tupla com o :noreply, tupla de names e refs
      {:ok, bucket} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV)
      ref = Process.monitor(bucket)
      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, bucket)
      {:noreply, {names, refs}}
      |>IO.inspect()
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    #resgatando informações
    #essa função é chamada quando o processo está morto
    #quando o processo morre ele retorna a seguinte mensagem
    #{:DOWN, ref, :process, object, reason}
    #já que as condições para quando o processo está morto conferem, removemos
    #o nome e as referencias do processo dos nossos mapas
    #por fim não retornamos nada para o cliente e retornamos os mapas atualizados
    {name, refs} = Map.pop(refs, ref)
    names = Map.delete(names, name)
    {:noreply, {names, refs}}
  end

  @impl true
  def handle_info(msg, state) do
    #usado para casos onde é passado algo que nosso server não espera
    require Logger
    Logger.debug("Não Conheço essa mensagem: #{inspect(msg)}")
    {:noreply, state}
  end
end
