defmodule KV.Server do
  require Logger

  def accept(port \\ 4000) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info("Aceito conexões na porta #{port}")

    loop(socket)
  end

  defp loop(socket) do
    IO.puts("ENTREI NO LOOP")
    {:ok, client} = :gen_tcp.accept(socket)
    Logger.info("Conectado ao Cliente #{inspect(client)}")

    {:ok, pid} =
      Task.Supervisor.start_child(KV.TaskSupervisor, fn ->
        serve(client)
      end)

    :ok = :gen_tcp.controlling_process(client, pid)
    Logger.info("VOU CHAMAR DE NOVO")
    loop(socket)
  rescue
    exc -> Logger.error("DEU RUIm #{inspect(exc)}")
  end

  defp serve(client) do
    with {:ok, data} <- :gen_tcp.recv(client, 0),
         {:ok, cmd} <- KV.Command.parse(data) do
      msg = KV.Command.run(cmd)
      write_line(client, msg)
    end

    serve(client)
  end

  defp write_line(client, {:ok, text}) do
    Logger.info("ENTREI AQUI")
    x = :gen_tcp.send(client, text)
    Logger.warning(inspect(x))
    x
  end

  defp write_line(client, {:error, :unkown_command}) do
    :gen_tcp.send(client, "NÃO CONHEÇO ESSE COMANDO\r\n")
  end

  defp write_line(client, {:error, {bucket, :not_found}}) do
    :gen_tcp.send(client, "BUCKET #{bucket} NÃO EXISTE\r\n")
  end

  defp write_line(_client, {:error, :closed}) do
    exit(:shutdown)
  end

  defp write_line(client, {:error, error}) do
    :gen_tcp.send(client, "ERROR: #{inspect(error)}\r\n")
    exit(error)
  end
end
