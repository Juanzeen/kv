defmodule KV do
  use Agent

  def start_link(opts) do
    Agent.start_link(fn -> %{} end, opts)
  end

  def append(pid, key, value) do
    #adicionando elementos no bucket quando dentro do nosso bucket temos uma lista
    Agent.update(pid, fn kv ->
      #mudando o estado do processo, passa inicialmente o processo (pid) e depois uma função anonima para alterar
      Map.update(kv, key, kv[key], fn values ->
        [value | values]
        #atualiza o nosso bucket, o primeiro parametro é um mapa(nosso bucket);
        #o segundo parametro é a chave a ser acessada;
        #o terceiro parametro é o default, caso a chave passada não exista, nós criamos essa chave e damos a ela o valor do default;
        #por fim temos a função que atualiza o valor
      end)
    end)
  end

  def put(pid, key, value) do
    #adiciona chaves com seus respectivos valores no bucket
    Agent.update(pid, fn kv ->
      #acessa o bucket e passa a como funcao anonima o map.put
      Map.put(kv, key, value)
      #recebe kv, o mapa
      #key, chave do mapa que vai ser adicionada
      #value, valor da chave que foi adicionada no mapa
    end)
  end

  def update(pid, key, value) do
    #atualizando o valor de uma chave no nosso bucket
    Agent.update(pid, fn kv ->
      #acessa o bucket e pega o mapa
      Map.update!(kv, key, fn _ -> value end)
      #função que atualiza o mapa
      #recebe o mapa, a chave que vai ser atualizada e a função para alterar o valor
      #foi usada update! ao invés de update, pois a variante com exclamação quebra quando dá erro
    end)
  end

  def get(pid, key) do
    #pega o valor de uma chave dentro do nosso bucket
    Agent.get(pid, fn kv -> kv[key] end)
  end

  def delete(pid, key) do
    #apaga uma chave dentro do nosso bucket
    Agent.update(pid, &Map.pop(&1, key))
    |> IO.inspect()
  end
end
