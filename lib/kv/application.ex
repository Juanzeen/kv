defmodule KV.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  #esse é o módulo da aplicação e nele é onde instanciamos nossos supervisores
  #o nosso Supervisor precisa inicialmente receber uma lista de childrens, que serão supervisionadas
  #logo após ele recebe as opts, que são as especificações do que ele deve fazer
  #como: estrategia de supervisionamento, nome, se deve reiniciar...
  #podemos passar outros supervisores como childrem, alias, fazemos isso nesse projeto

  @impl true
  def start(_type, _args) do
    children = [
      #inicia um supervisor de tarefas com o nome KV.TaskSupervisor
      {Task.Supervisor, name: KV.TaskSupervisor},
      #dá especificações sobre como tratar uma child específica, nesse caso a função do aceitar do server
      #passamos uma mapa com Task, para dizer que é uma tarefa e depois o nome da tarefa, após isso colocamos
      #que deve ser reiniciado permanentemente
      Supervisor.child_spec({Task, fn -> KV.Server.accept() end}, restart: :permanent),
      #criamos um supervisor dinamico que vai tratar dos nossos buckets, com a estratégia one_for_one
      {DynamicSupervisor, name: KV.BucketSupervisor, strategy: :one_for_one},
      #por fim indicamos que nosso supervisor deve cuidar do nosso KV.Registry
      {KV.Registry, name: KV.Registry}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_all, name: KV.Supervisor]
    #iniciamos nosso supervisor principal com suas childrens e opts
    Supervisor.start_link(children, opts)
  end
end
