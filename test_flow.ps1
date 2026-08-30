$registerBody = @{
    nome = "Admin"
    email = "admin3@quentinhas.com"
    senha = "password"
    role = "ADMIN"
} | ConvertTo-Json

$registerResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/register" -Method Post -ContentType "application/json" -Body $registerBody -ErrorAction SilentlyContinue

$loginBody = @{
    email = "admin3@quentinhas.com"
    senha = "password"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/login" -Method Post -ContentType "application/json" -Body $loginBody
$token = $loginResponse.token
$headers = @{
    "Authorization" = "Bearer $token"
}

Write-Host "0. Abrindo Caixa e Pegando Produto"
$caixaBody = @{
    saldoInicial = 100.0
} | ConvertTo-Json

$caixaResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/caixas/abrir" -Method Post -ContentType "application/json" -Headers $headers -Body $caixaBody -ErrorAction SilentlyContinue
if (-not $caixaResponse) {
    # already open, let's fetch active
    $caixaResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/caixas/ativo" -Method Get -Headers $headers
}
$caixaId = $caixaResponse.id

$catalogo = Invoke-RestMethod -Uri "http://localhost:8080/api/catalogo" -Method Get
$availableProduto = $catalogo.produtos | Where-Object { $_.tamanhos[0].disponivel -eq $true } | Select-Object -First 1
$produtoId = $availableProduto.tamanhos[0].ofertaId
$preco = $availableProduto.tamanhos[0].preco

Write-Host "1. Criando Pedido"
$body = @{
  caixaId = $caixaId
  cliente = @{
    nome = "Joao E2E"
    telefone = "11999999999"
  }
  modalidade = "ENTREGA"
  taxaEntrega = 5.0
  enderecoEntrega = "Rua Teste, 123"
  observacoes = ""
  total = ($preco * 2) + 5.0
  itens = @(
    @{
      ofertaId = $produtoId
      quantidade = 2
      precoUnitario = $preco
      subtotal = $preco * 2
    }
  )
  pagamento = @{
    formaPagamento = "DINHEIRO"
    valor = (($preco * 2) + 5.0)
    valorRecebido = 100.0
    troco = 100.0 - (($preco * 2) + 5.0)
  }
  provedorEvento = "LOCAL"
  externalEventId = "evt_$(Get-Random)"
} | ConvertTo-Json -Depth 10

try {
  $response = Invoke-RestMethod -Uri "http://localhost:8080/api/pedidos" -Method Post -ContentType "application/json" -Headers $headers -Body $body
  Write-Host ($response | ConvertTo-Json)
} catch {
  Write-Host "Error creating pedido:"
  Write-Host $_.ErrorDetails.Message
}

Start-Sleep -Seconds 1

Write-Host "2. Buscando pedidos reais da KDS"
$pedidos = Invoke-RestMethod -Uri "http://localhost:8080/api/pedidos" -Method Get -Headers $headers
$joao = $pedidos | Where-Object { $_.clienteNome -eq "Joao E2E" } | Select-Object -Last 1
Write-Host ($joao | ConvertTo-Json -Depth 10)

$id = $joao.id
Write-Host "3. Transicionando Status para EM_PRODUCAO no pedido $id"

$transicaoBody = @{
    status = "EM_PRODUCAO"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8080/api/pedidos/$id/transicao" -Method Post -ContentType "application/json" -Headers $headers -Body $transicaoBody

Write-Host "4. Verificando Status no Banco"
$pedidosAtualizados = Invoke-RestMethod -Uri "http://localhost:8080/api/pedidos" -Method Get -Headers $headers
$joaoAtualizado = $pedidosAtualizados | Where-Object { $_.id -eq $id }
Write-Host ($joaoAtualizado | ConvertTo-Json -Depth 10)
