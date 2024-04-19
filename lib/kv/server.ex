defmodule KV.Server do
  require Logger

  def accept(port \\ 4000) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info("Aceito conexões na porta #{port}")

    loop(socket)
  end

  defp loop(socket) do
    #função que aceita as conexões do cliente e inicia novas taredas para cada cliente
    IO.puts("ENTREI NO LOOP")
    {:ok, client} = :gen_tcp.accept(socket)
    #aceita a conexão do cliente ao socket (provedor da comunicação entre duas portas, two way communication)
    Logger.info("Conectado ao Cliente #{inspect(client)}")

    {:ok, pid} =
      Task.Supervisor.start_child(KV.TaskSupervisor, fn ->
        serve(client)
      end)
      #inicia  um um supervisor de taskas que vai ter como startchild
      #executar e monitorar a função serve

    :ok = :gen_tcp.controlling_process(client, pid)
    #associa um novo controle de processo do pid ao socket;
    #o controlling_process é o processo que recebe mensagens do socket
    Logger.info("VOU CHAMAR DE NOVO")
    loop(socket)
    #a função se chama novamente para que o loop funcione
  rescue
    exc -> Logger.error("DEU RUIm #{inspect(exc)}")
  end

  defp serve(client) do
    #função que lê e escreve uma linha
    #basicamente iniciamos utilizando o with, só executa o que vem após caso
    #o que foi passado para ele seja true
    #então, se a função :gen_tcp.recv me retornar um {:ok, data}
    #e o meu parse me retornar um comando e não um erro, minha mensagem
    #vai ser o run do meu comando, que pode ser: criar, atualizar, deletar ou ver
    #por fim, eu retorno para o cliente a mensagem, que vai depender do retorno
    #oferecido pela função run

    with {:ok, data} <- :gen_tcp.recv(client, 0),
      #recv -> recee os dados do scoket, recebendo como parametros o socket/client e 0
      #0 se refere ao tamanho do socket
         {:ok, cmd} <- KV.Command.parse(data) do
      msg = KV.Command.run(cmd)
      write_line(client, msg)
    end

    serve(client)
  end

  defp write_line(client, {:ok, text}) do
    Logger.info("ENTREI AQUI")
    x = :gen_tcp.send(client, text)
    #envia o pacote/linha para o cliente;
    #recebe como parametro o socket;client e o text é a msg retornada do run
    #de command, então pode ser o valor de uma chave no bucket, um simples OK, etc...
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
