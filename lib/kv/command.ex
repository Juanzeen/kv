defmodule KV.Command do
  def parse(line) do
    #pega a linha passada no nosso servidor e analisa ela para dar um retorno que será usado
    #como parametro para uma função no servidor
    case String.split(line) do
      ["CREATE", bucket] -> {:ok, {:create, bucket}}
      ["GET", bucket, key] -> {:ok, {:get, bucket, key}}
      ["PUT", bucket, key, value] -> {:ok, {:put, bucket, key, value}}
      ["DELETE", bucket, key] -> {:ok, {:delete, bucket, key}}
      _ -> {:error, :unkown_command}
    end
  end

  def run({:create, bucket}) do
    #cria o bucket que irá guardar as informações
    KV.Registry.create(bucket)
    {:ok, "Bucket criado!\r\n"}
  end

  def run({:get, bucket, key}) do
    IO.inspect(bucket)
    #mostra um valor presente no bucket após passar o nome do bucket e a chave
    lookup_and(bucket, fn pid ->
      value = KV.get(pid, key)
      {:ok, "O valor dessa chave é: #{value}\r\n"}
    end)
  end

  def run({:put, bucket, key, value}) do
    #adiciona uma chave e um valor no bucket
    lookup_and(bucket, fn pid ->
      KV.put(pid, key, value)
      {:ok, "Chave #{key} adicionada com o valor #{value}\r\n"}
    end)
  end

  def run({:delete, bucket, key}) do
    #apaga uma chave do bucket
    lookup_and(bucket, fn pid ->
      KV.delete(pid, key)
      {:ok, "Chave #{key} deletada!\r\n"}
    end)
  end

  defp lookup_and(bucket, callback) do
    #função que verifica se existe um bucket com o nome passado pelo cliente
    #invocamos o nosso lookup do Registry que retorna :reply, {:ok, pid}, {%{names, bucket}, %{refs, names}}
    #com base nisso usamos nosso case
    #caso exista ele retorna um tupla {:ok, pid} e executa uma função de callback que é diferente em cada comando
    #caso não exista temos um erro
    case KV.Registry.lookup(bucket) do
      {:ok, pid} -> callback.(pid)
      :error -> {:error, {bucket, :not_found}}
    end
  end
end
