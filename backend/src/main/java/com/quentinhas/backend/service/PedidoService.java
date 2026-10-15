package com.quentinhas.backend.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.core.type.TypeReference;
import com.quentinhas.backend.dto.request.PedidoRequest;
import com.quentinhas.backend.dto.request.ItemPedidoRequest;
import com.quentinhas.backend.dto.response.PedidoResponse;
import com.quentinhas.backend.dto.response.PedidoDetalheResponse;
import com.quentinhas.backend.exception.BusinessRuleException;
import com.quentinhas.backend.exception.IdempotencyException;
import com.quentinhas.backend.exception.StockEsgotadoException;
import com.quentinhas.backend.model.*;
import com.quentinhas.backend.repository.*;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@Service
public class PedidoService {

    private final JdbcTemplate jdbcTemplate;
    private final ObjectMapper snakeCaseMapper;
    private final ProdutoRepository produtoRepository;
    private final ProdutoVariacaoRepository variacaoRepository;
    private final AdicionalRepository adicionalRepository;
    private final PedidoRepository pedidoRepository;

    public PedidoService(JdbcTemplate jdbcTemplate, ProdutoRepository produtoRepository, 
                         ProdutoVariacaoRepository variacaoRepository, AdicionalRepository adicionalRepository,
                         PedidoRepository pedidoRepository) {
        this.jdbcTemplate = jdbcTemplate;
        this.produtoRepository = produtoRepository;
        this.variacaoRepository = variacaoRepository;
        this.adicionalRepository = adicionalRepository;
        this.pedidoRepository = pedidoRepository;
        this.snakeCaseMapper = new ObjectMapper()
                .setPropertyNamingStrategy(PropertyNamingStrategies.SNAKE_CASE);
    }

    @Transactional
    public PedidoResponse criarPedido(PedidoRequest request) {
        Integer isCaixaAberto = jdbcTemplate.queryForObject(
            "SELECT count(*) FROM caixas WHERE id = ? AND status = 'ABERTO'",
            Integer.class, request.caixaId()
        );
        if (isCaixaAberto == null || isCaixaAberto == 0) {
            throw new BusinessRuleException("Caixa " + request.caixaId() + " não está aberto.");
        }

        UUID clienteId = null;
        if (request.cliente() != null && request.cliente().telefone() != null) {
            clienteId = jdbcTemplate.queryForObject(
                "INSERT INTO clientes (telefone, nome) VALUES (?, ?) ON CONFLICT (telefone) DO UPDATE SET nome = EXCLUDED.nome RETURNING id",
                UUID.class, request.cliente().telefone(), request.cliente().nome()
            );
        }

        try {
            Pedido pedido = new Pedido();
            pedido.setCaixaId(request.caixaId());
            pedido.setClienteId(clienteId);
            pedido.setModalidade(request.modalidade());
            pedido.setTaxaEntrega(request.taxaEntrega() != null ? request.taxaEntrega() : BigDecimal.ZERO);
            pedido.setEnderecoEntrega(request.enderecoEntrega());
            pedido.setObservacoes(request.observacoes());
            pedido.setProvedorEvento(request.provedorEvento());
            pedido.setExternalEventId(request.externalEventId());
            
            String seqStr = jdbcTemplate.queryForObject("SELECT nextval('seq_pedido_comercial')", String.class);
            pedido.setNumeroComercial("#QP-" + seqStr);

            BigDecimal totalPedido = pedido.getTaxaEntrega();

            for (ItemPedidoRequest itemReq : request.itens()) {
                ProdutoVariacao variacao = variacaoRepository.findById(itemReq.variacaoId())
                    .orElseThrow(() -> new BusinessRuleException("Variação não encontrada: " + itemReq.variacaoId()));
                
                if (!variacao.isAtivo()) {
                    throw new BusinessRuleException("Variação inativa: " + variacao.getTamanho());
                }

                Produto produto = produtoRepository.findByIdWithPessimisticLock(variacao.getProduto().getId())
                    .orElseThrow(() -> new BusinessRuleException("Produto não encontrado."));

                int qtd = itemReq.quantidade();
                if (qtd <= 0) throw new BusinessRuleException("Quantidade inválida");

                if (produto.getEstoqueAtual() < qtd) {
                    throw new StockEsgotadoException("Estoque esgotado para " + produto.getNome());
                }

                produto.setEstoqueAtual(produto.getEstoqueAtual() - qtd);
                produtoRepository.save(produto);

                ItemPedido itemPedido = new ItemPedido();
                itemPedido.setVariacao(variacao);
                itemPedido.setQuantidade(qtd);
                itemPedido.setPrecoUnitario(variacao.getPreco());
                itemPedido.setPrecoUnitarioAplicado(variacao.getPreco());
                itemPedido.setObservacoes(itemReq.observacoes());

                BigDecimal subtotalItem = variacao.getPreco().multiply(BigDecimal.valueOf(qtd));

                if (itemReq.adicionaisIds() != null) {
                    for (UUID addId : itemReq.adicionaisIds()) {
                        Adicional adicional = adicionalRepository.findById(addId)
                            .orElseThrow(() -> new BusinessRuleException("Adicional não encontrado"));
                        
                        PedidoItemAdicional pia = new PedidoItemAdicional();
                        pia.setAdicional(adicional);
                        pia.setPrecoAplicado(adicional.getPreco());
                        itemPedido.adicionarAdicional(pia);

                        subtotalItem = subtotalItem.add(adicional.getPreco().multiply(BigDecimal.valueOf(qtd)));
                    }
                }

                itemPedido.setSubtotal(subtotalItem);
                itemPedido.setSubtotalAplicado(subtotalItem);
                
                pedido.adicionarItem(itemPedido);
                totalPedido = totalPedido.add(subtotalItem);
            }

            pedido.setTotal(totalPedido);

            if (request.pagamento() != null) {
                Pagamento p = new Pagamento();
                p.setFormaPagamento(request.pagamento().formaPagamento());
                p.setValor(totalPedido); 
                p.setValorRecebido(request.pagamento().valorRecebido());
                
                if (p.getValorRecebido() != null && p.getFormaPagamento().equals("DINHEIRO")) {
                    p.setTroco(p.getValorRecebido().subtract(totalPedido));
                    if (p.getTroco().compareTo(BigDecimal.ZERO) < 0) {
                        throw new BusinessRuleException("Valor recebido insuficiente.");
                    }
                }
                pedido.adicionarPagamento(p);
            }

            pedidoRepository.saveAndFlush(pedido);
            return new PedidoResponse(pedido.getId(), pedido.getNumeroComercial(), "SUCCESS");

        } catch (DataIntegrityViolationException e) {
            Throwable cause = e;
            while (cause != null) {
                if (cause.getMessage() != null && cause.getMessage().contains("external_event_id_key")) {
                    throw new IdempotencyException("Pedido duplicado. Evento já processado.");
                }
                cause = cause.getCause();
            }
            throw e;
        }
    }

    public List<PedidoDetalheResponse> obterPedidos() {
        String sql = """
            SELECT json_agg(
                json_build_object(
                    'id', p.id,
                    'cliente_nome', c.nome,
                    'cliente_telefone', c.telefone,
                    'status_operacional', p.status_operacional,
                    'status_financeiro', p.status_financeiro,
                    'modalidade', p.modalidade,
                    'endereco_entrega', p.endereco_entrega,
                    'taxa_entrega', p.taxa_entrega,
                    'forma_pagamento', pg.forma_pagamento,
                    'troco', pg.troco,
                    'total', p.total,
                    'registrado_em', p.criado_em,
                    'itens', COALESCE((
                         SELECT json_agg(json_build_object(
                             'oferta_id', ip.variacao_id,
                             'nome_produto', pr.nome,
                             'sigla_tamanho', v.tamanho,
                             'quantidade', ip.quantidade,
                             'preco_unitario', ip.preco_unitario_aplicado,
                             'subtotal', ip.subtotal_aplicado
                         ))
                         FROM itens_pedido ip
                         LEFT JOIN produto_variacoes v ON ip.variacao_id = v.id
                         LEFT JOIN produtos pr ON v.produto_id = pr.id
                         WHERE ip.pedido_id = p.id
                    ), '[]'::json)
                )
            )
            FROM pedidos p
            LEFT JOIN clientes c ON p.cliente_id = c.id
            LEFT JOIN pagamentos pg ON pg.pedido_id = p.id
            WHERE p.status_operacional != 'ENTREGUE' AND p.status_operacional != 'CANCELADO'
            """;

        String jsonResult = jdbcTemplate.queryForObject(sql, String.class);
        if (jsonResult == null || jsonResult.equals("null")) {
            return List.of();
        }
        
        try {
            return snakeCaseMapper.readValue(jsonResult, new TypeReference<List<PedidoDetalheResponse>>() {});
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Erro ao converter json dos pedidos", e);
        }
    }

    private static final java.util.Set<String> STATUS_VALIDOS = java.util.Set.of(
        "RASCUNHO", "CONFIRMADO", "EM_PRODUCAO", "PRONTO", "SAIU_ENTREGA", "ENTREGUE", "CANCELADO"
    );

    public void atualizarStatusOperacional(UUID pedidoId, String status) {
        if (status == null || !STATUS_VALIDOS.contains(status.trim().toUpperCase())) {
            throw new IllegalArgumentException("Status operacional inválido: " + status);
        }
        String statusFormatado = status.trim().toUpperCase();

        String statusAtual = jdbcTemplate.query(
            "SELECT status_operacional FROM pedidos WHERE id = ?",
            rs -> rs.next() ? rs.getString("status_operacional") : null,
            pedidoId
        );

        if (statusAtual == null) {
            throw new IllegalArgumentException("Pedido não encontrado");
        }

        if (statusFormatado.equals(statusAtual)) {
            return;
        }

        if ("ENTREGUE".equals(statusAtual) || "CANCELADO".equals(statusAtual)) {
            throw new BusinessRuleException("Pedido já finalizado no status " + statusAtual + " não permite alteração operacional.");
        }

        boolean transicaoValida = switch (statusAtual) {
            case "RASCUNHO" -> statusFormatado.equals("CONFIRMADO") || statusFormatado.equals("CANCELADO");
            case "CONFIRMADO" -> statusFormatado.equals("EM_PRODUCAO") || statusFormatado.equals("CANCELADO");
            case "EM_PRODUCAO" -> statusFormatado.equals("PRONTO") || statusFormatado.equals("CANCELADO");
            case "PRONTO" -> statusFormatado.equals("SAIU_ENTREGA") || statusFormatado.equals("ENTREGUE") || statusFormatado.equals("CANCELADO");
            case "SAIU_ENTREGA" -> statusFormatado.equals("ENTREGUE") || statusFormatado.equals("CANCELADO");
            default -> false;
        };

        if (!transicaoValida) {
            throw new BusinessRuleException("Transição inválida de " + statusAtual + " para " + statusFormatado);
        }

        jdbcTemplate.update(
            "UPDATE pedidos SET status_operacional = ? WHERE id = ?",
            statusFormatado, pedidoId
        );
    }
}
