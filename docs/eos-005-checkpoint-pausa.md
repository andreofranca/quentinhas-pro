# CHECKPOINT DE PAUSA — EOS-005.3

Este documento registra o estado exato e inalterado do ambiente do projeto antes de uma pausa de sessão. Garante que o ponto de retomada seja perfeitamente documentado e preservado.

## 1. Estado do Controle de Versão (Git/GitHub)
- **Baseline Cloud:** Já versionado e consolidado no repositório remoto.
- **Commit Principal de Referência:** `628d81f896e39369ce35ad7ae30909ea75f05e02`
- O diretório de trabalho encontra-se limpo, ressalvado este próprio documento de checkpoint.
- **Nenhuma migration Cloud foi executada.**

## 2. Estado da Infraestrutura Cloud (Supabase)
- A **Supabase CLI está autenticada** via token com sucesso.
- O único projeto Cloud mapeado na conta é o legado original: **`lanchonete-controle`**. Ele está categoricamente isolado e **proibido** de receber qualquer nova operação ou link.
- O novo projeto Cloud (**`quentinhas-pro`**) **ainda não foi criado** no Dashboard.
- Devido à ausência do ambiente de destino correto, **nenhum comando de vínculo** (`supabase link`) ou **sincronização de banco** (`supabase db push`) foi operado. O ambiente Cloud permanece intacto.

## 3. Estado do Laboratório Local e Testes
- **A Transition Engine está Validada:** Todas as simulações do ambiente Docker (EOS-005.1) foram concluídas sem quebras.
- **Confiabilidade ACID:** Teste extremo de concorrência com 50 disparos simultâneos disputando 10 itens resultou perfeitamente em 10 pedidos gerados e 40 lockouts, comprovando as políticas de transação Pessimistic Lock.
- **Testes de Contrato:** 41 instâncias do `flutter test` foram aprovadas.

## 4. Estado da Aplicação (Frontend)
Os componentes, fluxos e contratos estabelecidos anteriormente permanecem prontos e intocados:
- Fundação Visual da Solução.
- Dashboard Operacional Mock.
- Carrinho Quentinha e Validação Dinâmica P/M/G.
- Checkout Integrado, Tratativas de CEP, Endereço e Troco.
- Disparo Duplo de Notificações via WhatsApp (Operação/Cliente).
- Invariantes de Disponibilidade de Estoque na Interface.
- Objeto de Transição `PedidoDraft` mapeado de ponta a ponta com a Transition Engine.

## 5. Próximo Passo Exclusivo na Retomada
1. O PO deve criar um novo projeto limpo e dedicado no **Supabase Dashboard** (`quentinhas-pro`).
2. Retomada da auditoria de identificação do novo ambiente Cloud pela CLI para garantir o apontamento seguro.
3. Somente após a confirmação inequívoca do novo projeto: realizar o Link local-nuvem.
