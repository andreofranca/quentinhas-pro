package com.quentinhas.backend;

import com.quentinhas.backend.dto.request.ItemPedidoRequest;
import com.quentinhas.backend.dto.request.PagamentoRequest;
import com.quentinhas.backend.dto.request.PedidoRequest;
import com.quentinhas.backend.exception.StockEsgotadoException;
import com.quentinhas.backend.model.Produto;
import com.quentinhas.backend.model.ProdutoVariacao;
import com.quentinhas.backend.repository.ProdutoRepository;
import com.quentinhas.backend.repository.ProdutoVariacaoRepository;
import com.quentinhas.backend.service.PedidoService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@ActiveProfiles("test")
public class PedidoConcurrencyTest extends AbstractIntegrationTest {

    @Autowired
    private PedidoService pedidoService;

    @Autowired
    private ProdutoRepository produtoRepository;

    @Autowired
    private ProdutoVariacaoRepository variacaoRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private UUID caixaId;
    private Produto produto;
    private ProdutoVariacao variacao;

    @BeforeEach
    void setup() {
        jdbcTemplate.execute("DELETE FROM itens_pedido");
        jdbcTemplate.execute("DELETE FROM pagamentos");
        jdbcTemplate.execute("DELETE FROM pedidos");
        jdbcTemplate.execute("DELETE FROM produto_variacoes");
        jdbcTemplate.execute("DELETE FROM caixas");
        jdbcTemplate.execute("DELETE FROM usuarios");

        UUID userId = jdbcTemplate.queryForObject("INSERT INTO usuarios (nome, email, password_hash, role) VALUES ('Admin', 'admin@test.com', 'hash', 'ADMIN') RETURNING id", UUID.class);
        caixaId = jdbcTemplate.queryForObject("INSERT INTO caixas (operador_id, terminal_id, status) VALUES (?, 'CAIXA_TEST', 'ABERTO') RETURNING id", UUID.class, userId);

        produto = new Produto();
        produto.setNome("Carne Assada");
        produto.setCategoria("Refeição");
        produto.setPrecoBase(new BigDecimal("20.00"));
        produto.setEstoqueAtual(10);
        produto.setEstoqueMinimo(5);
        produtoRepository.save(produto);

        variacao = new ProdutoVariacao();
        variacao.setProduto(produto);
        variacao.setTamanho("MEDIA");
        variacao.setPreco(new BigDecimal("25.00"));
        variacao.setAtivo(true);
        variacaoRepository.save(variacao);
    }

    @Test
    void testConcorrencia_Estoque10_Compras50() throws InterruptedException {
        int numThreads = 50;
        ExecutorService executor = Executors.newFixedThreadPool(numThreads);
        CountDownLatch latch = new CountDownLatch(1);
        CountDownLatch doneLatch = new CountDownLatch(numThreads);

        AtomicInteger sucessos = new AtomicInteger(0);
        AtomicInteger falhas = new AtomicInteger(0);

        for (int i = 0; i < numThreads; i++) {
            executor.submit(() -> {
                try {
                    latch.await();
                    PedidoRequest request = new PedidoRequest(
                            caixaId,
                            null,
                            "RETIRADA",
                            BigDecimal.ZERO,
                            null,
                            "",
                            List.of(new ItemPedidoRequest(variacao.getId(), 1, List.of(), "")),
                            new PagamentoRequest("PIX", new BigDecimal("25.00"), null, null),
                            "APP",
                            UUID.randomUUID().toString()
                    );
                    pedidoService.criarPedido(request);
                    sucessos.incrementAndGet();
                } catch (Exception e) {
                    falhas.incrementAndGet();
                } finally {
                    doneLatch.countDown();
                }
            });
        }

        latch.countDown(); // start all
        doneLatch.await(); // wait all

        assertThat(sucessos.get()).isEqualTo(10);
        assertThat(falhas.get()).isEqualTo(40);

        Produto p = produtoRepository.findById(produto.getId()).orElseThrow();
        assertThat(p.getEstoqueAtual()).isEqualTo(0);
    }

    @Test
    void testConcorrencia_Estoque1_Compras2() throws InterruptedException {
        produto.setEstoqueAtual(1);
        produtoRepository.save(produto);

        int numThreads = 2;
        ExecutorService executor = Executors.newFixedThreadPool(numThreads);
        CountDownLatch latch = new CountDownLatch(1);
        CountDownLatch doneLatch = new CountDownLatch(numThreads);

        AtomicInteger sucessos = new AtomicInteger(0);
        AtomicInteger falhas = new AtomicInteger(0);

        for (int i = 0; i < numThreads; i++) {
            executor.submit(() -> {
                try {
                    latch.await();
                    PedidoRequest request = new PedidoRequest(
                            caixaId,
                            null,
                            "RETIRADA",
                            BigDecimal.ZERO,
                            null,
                            "",
                            List.of(new ItemPedidoRequest(variacao.getId(), 1, List.of(), "")),
                            new PagamentoRequest("PIX", new BigDecimal("25.00"), null, null),
                            "APP",
                            UUID.randomUUID().toString()
                    );
                    pedidoService.criarPedido(request);
                    sucessos.incrementAndGet();
                } catch (Exception e) {
                    falhas.incrementAndGet();
                } finally {
                    doneLatch.countDown();
                }
            });
        }

        latch.countDown();
        doneLatch.await();

        assertThat(sucessos.get()).isEqualTo(1);
        assertThat(falhas.get()).isEqualTo(1);

        Produto p = produtoRepository.findById(produto.getId()).orElseThrow();
        assertThat(p.getEstoqueAtual()).isEqualTo(0);
    }
}
