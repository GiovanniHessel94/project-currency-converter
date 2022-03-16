# Project-Currency-Converter
[![codecov](https://codecov.io/gh/GiovanniHessel94/project-currency-converter/branch/main/graph/badge.svg?token=I7IZANZ00E)](https://codecov.io/gh/GiovanniHessel94/project-currency-converter)

O projeto CurrencyConverter foi desenvolvido para conclusão de um desafio de código (code challenge) sobre o desenvolvimento back end utilizando a linguagem Elixir.

## O Desafio

O desafio consiste na implementação de uma API REST que tem como principal objetivo realizar a conversão entre duas moedas utilizando a API externa [exchangerates](https://exchangeratesapi.io/) para obtenção, em tempo real, das taxas de conversão utilizadas no mercado internacional. Uma limitação importante do desafio é que, na integração com o serviço exchangerates, só é permitido utilizar a versão sem custo que disponibiliza as taxas de conversão de moedas estrangeiras somente com base no EURO, assim efetivamente todas as conversões devem ser realizadas utilizando as taxas de conversão do EURO. Além disso, para executar a operação de conversão deve ser recebido um id de usuário que será utilizado posteriormente para consultar as conversões realizadas por aquele usuário.

A API REST implementada deve possuir dois endpoints, sendo eles:
* Um endpoint que recebe o id do usuário, moeda de origem, moeda de destino e o valor a ser convertido e retorna, além destes dados, o id da conversão, taxa de conversão utilizada, valor convertido e data e hora UTC.
* Um endpoint que deve listar todas as conversões realizadas por um usuário.

Um outro detalhe importante é que o valor convertido não deve ser armazenado no banco de dados, visto que ele é calculável com os demais campos armazenados, sendo eles o valor a ser convertido e a taxa de conversão utilizada.

## A Implementação

### Tecnologias
Foram utilizadas as seguintes tecnologias na implementação do desafio:
* Para construção da API REST foi utilizado o framework [Phoenix](https://www.phoenixframework.org/) juntamente com [Ecto](https://hexdocs.pm/phoenix/ecto.html), visto que atualmente este é o "framework padrão" utilizado pela comunidade elixir e atende tranquilamente as demandas deste projeto.
* Para persistir as informações foi utilizado o banco [Postgres](https://www.postgresql.org/), também considerado um padrão no desenvolvimento de aplicações elixir. 
* Para armazenar e disponibilizar para consulta os logs das requições recebidas e realizadas pela aplicação, foi utilizado o [Elastic Search Cloud](https://www.elastic.co/pt/cloud/), por ser uma referência no mercado e por eu já experimentado o [Kibana](https://www.elastic.co/pt/kibana/) para visualização dos logs.
* Para realizar as requisições aos serviços exchangerates e elastic search foi utilizada a biblioteca [HTTPoison](https://github.com/edgurgel/httpoison).
* Para gerenciar e personalizar as "retentativas" (retry) das requisições efetuadas foi utilizada a biblioteca [ExternalService](https://github.com/jvoegele/external_service). 
* Para efetuar os calculos de maneira precisa foi utilizada a biblioteca [Decimal](https://github.com/ericmj/decimal).
* Para efetuar os testes automatizados, foi importante a utilização das bibliotecas [Mox](https://github.com/dashbitco/mox) e [Bypass](https://github.com/PSPDFKit-labs/bypass).
* Para disponibilização da aplicação foi utilizada a plataforma [Gigalixir](https://www.gigalixir.com/) pela facilidade em realizar o deploy de uma aplicação e por eu já ter utilizado este serviço anteriormente.

### Estrutura do projeto
A estrutura do projeto segue a [estrutura padrão de um projeto phoenix](https://hexdocs.pm/phoenix/directory_structure.html). Com relação a estrutura na pasta referente a "domínios e lógicas de negócio", ``lib/currency_converter``, a estruturação das subpastas foi realizada com base nos contextos e os módulos foram definidos tendo como objetivo implementar uma estrutura vista em curso, apelidada de command call, onde cada módulo tem apenas uma função pública chamada ``call`` e a função do módulo é definida pelo seu nome juntamente com seu contexto.

#### Estrutura padrão de um projeto phoenix
```
├── _build
├── assets
├── config
├── deps
├── lib
│   ├── hello
│   ├── hello.ex
│   ├── hello_web
│   └── hello_web.ex
├── priv
└── test
```
### Endpoints

#### Informações Importantes
É preciso salientar algumas informações importantes:
* O id do usuário  deve ser um inteiro ou um UUID. Essa restrição foi feita pensando nas formas mais comuns de representar o id de um usuário.
* A API suporta operações sobre valores com até 33 digitos na parte inteira e 5 digitos nas casas decimais.
* É recomendado informar os valores no formato de string, em caso de floats, ou inteiros. É possível informar valores como floats, porém podem haver problemas na conversão desses números.
* Números com mais de 5 casas decimais terão os valores após a 5ª casa decimal ignorados.
* Os valores são sempre retornados no formato de string e com 5 casas decimais.
* As taxas de conversão são retornadas no formato de string.
* A lista das moedas disponíveis está presente [neste arquivo de constantes](https://github.com/GiovanniHessel94/project-currency-converter/blob/main/lib/currency_converter/constants/currencies.ex)

#### Endpoint de Conversão
**Método HTTP:** POST  
**Caminho:** api/conversions  
**Corpo da Requisição:**
```
{
	"user_id": <id do usuário>,
	"source_currency": <moeda de origem>,
	"source_amount": <valor a ser convertido>,
	"destination_currency": <moeda de destino>
}
```
**Corpo da Resposta:**
```
{
	"data": {
		"conversion": {
			"destination_amount": <valor convertido>,
			"destination_currency": <moeda de destino>,
			"exchange_rate": <taxa de conversão>,
			"id": <uuid da conversão>,
			"processed_at": <data hora do processamento>,
			"source_amount": <valor a ser convertido>,
			"source_currency": <moeda de origem>,
			"user_id": <id do usuário>
		}
	},
	"success": true
}
```
#### Endpoint de Consulta de Conversões de um usuário
**Método HTTP:** GET  
**Caminho:** api/conversions/<id do usuário>?page=1<demais parâmetros opcionais>  
**Parâmetros de paginação:**
* **page:** Inteiro indicando a página que deve ser exibida, **obrigatório.**
* **limit:** Inteiro indicando o limite de registros por página, possui valor padrão de 25.
* **order_direction:** String indicando a direção da ordenação sobre a data hora do processamento, "ASC" indica ascendente e "DESC" indica descendente. Possui valor padrão "DESC".

**Corpo da Requisição:** <vazio>  
**Corpo da Resposta:**
```
{
	"data": {
		"conversions": [
			{
    			"destination_amount": <valor convertido>,
    			"destination_currency": <moeda de destino>,
    			"exchange_rate": <taxa de conversão>,
    			"id": <uuid da conversão>,
    			"processed_at": <data hora do processamento>,
    			"source_amount": <valor a ser convertido>,
    			"source_currency": <moeda de origem>,
    			"user_id": <id do usuário>
		    }
		]
	},
	"metadata": {
		"limit": <limite de registros por página>,
		"order_direction": <direção da ordenação>,
		"page": <página>
	},
	"success": true
}
```

#### Padrão de Erros
Os erros seguem o seguinte padrão de retorno:
```
{
	"errors"<opcional>: {
		<campo>: [<errors relacionados ao campo>]
	},
	"reason": <razão do erro>,
	"success": false
}
```
É importante salientar que o campo ``errors`` não é sempre retornado.

### Logs no Elastic Search Cloud
Os logs das requisições integrados ao elastic search permitem a consulta de todas as requisições, e respostas, recebidas ou efetuadas pelo sistema. Inclusive, com a utilização do Kibana é possível fazer o filtro por diversos campos.

##### Visão Geral
![Falha ao carregar imagem](https://user-images.githubusercontent.com/26199302/158186991-a2a3a947-9534-4dda-98bf-1074316c1289.png "Requests logs - Kibana")

##### Exemplo de requisição efetuada ao serviço exchangerates.
![Falha ao carregar imagem](https://user-images.githubusercontent.com/26199302/158189248-6ad413e0-8df7-487e-8e85-0345390173df.png "Requisição efetuada ao serviço Exchange Rates")


### Servidor em Produção
[Este](https://pink-murky-amphiuma.gigalixirapp.com/) é o link onde as requisições devem ser efetuadas em produção.

## Executando localmente

### Pré-requisitos

Recomenda-se a instalação das mesmas versões utilizadas durante o desenvolvimento, ambas estão especificadas no arquivo ``.tool-versions``, sendo elas:
* Versão `22.3.4.24` do erlang.
* Versão `1.13.3` do elixir.

### Variáveis de ambiente
Para executar a aplicação é necessário definir algumas variáveis de ambiente, a lista das variáveis está presente no arquivo ``.env``, porém vamos descrever cada uma:
* ELASTIC_SEARCH_API_ENABLED: Essa variável deve conter o valor "true" ou "false". Caso "true" a aplicação irá tentar enviar os logs ao elastic search, assim as demais variáveis de ambiente do elastic search devem estar configuradas corretamente.
* ELASTIC_SEARCH_API_BASE_URL: URL de acesso ao serviço do elastic search.
* ELASTIC_SEARCH_API_USERNAME: Usuário de acesso ao serviço do elastic search.
* ELASTIC_SEARCH_API_PASSWORD: Senha de acesso ao serviço do elastic search.
* EXCHANGE_RATES_API_BASE_URL: URL de acesso ao serviço do exchangerates.
* EXCHANGE_RATES_API_ACCESS_KEY: Chave de acesso ao serviço do exchangerates.

### Comandos

Instalando as dependências:
```
mix deps.get
```
Iniciando o servidor localmente:
```
mix phx.server
```

## Autor

Giovanni Hessel\
[@Linkedin](https://www.linkedin.com/in/giovanni-hessel-137b1393/)
