defmodule KV.Command do
  def parse(line) do
    case String.split(line) do
      ["CREATE", bucket] -> {:ok, {:create, bucket}}
      ["GET", bucket, key] -> {:ok, {:get, bucket, key}}
      ["PUT", bucket, key, value] -> {:ok, {:put, bucket, key, value}}
      ["DELETE", bucket, key] -> {:ok, {:delete, bucket, key}}
      _ -> {:error, :unkown_command}
    end
  end

  def run({:create, bucket}) do
    KV.Registry.create(bucket)
    {:ok, "OK\r\n"}
  end

  def run({:get, bucket, key}) do
    lookup_and(bucket, fn pid ->
      value = KV.get(pid, key)
      {:ok, "#{value}\r\nOK\r\n"}
    end)
  end

  def run({:put, bucket, key, value}) do
    lookup_and(bucket, fn pid ->
      KV.put(pid, key, value)
      {:ok, "OK\r\n"}
    end)
  end

  def run({:delete, bucket, key}) do
    lookup_and(bucket, fn pid ->
      KV.delete(pid, key)
      {:ok, "OK\r\n"}
    end)
  end

  defp lookup_and(bucket, callback) do
    case KV.Registry.lookup(bucket) do
      {:ok, pid} -> callback.(pid)
      :error -> {:error, {bucket, :not_found}}
    end
  end
end
