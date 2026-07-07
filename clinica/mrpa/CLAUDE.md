# MRPA — Regras do sistema

Processamento de tabelas manuscritas de Monitorização Residencial da Pressão Arterial.

## Protocolo

1. **Excluir o Dia 1** dos cálculos.
2. **Excluir medidas discrepantes** (ver critérios abaixo) antes de calcular médias.
3. Calcular médias de **PAS** e **PAD** para:
   - manhã
   - noite
   - geral
4. Aplicar os cortes de normalidade:
   - **PAS < 135 mmHg**
   - **PAD < 85 mmHg**
5. **Sinalizar**:
   - valores implausíveis (ver critérios abaixo)
   - padrões de *reverse-dipping* (PA noturna > PA matinal)
   - exames com número de medidas válidas abaixo do mínimo

---

## Critérios de exclusão de medidas discrepantes

Excluir a medida quando qualquer uma das condições abaixo for verdadeira
(salvo justificativa clínica documentada):

| Critério | Condição de exclusão |
|---|---|
| PAD muito alta | PAD > 140 mmHg |
| PAD muito baixa | PAD < 40 mmHg |
| PAS muito baixa | PAS < 70 mmHg |
| PAS muito alta | PAS > 250 mmHg |
| Pressão de pulso estreita | PP < 20 mmHg (PP = PAS − PAD) |
| Pressão de pulso ampla | PP > 100 mmHg |

> **Pressão de pulso (PP)** = PAS − PAD. Calculada por medida individualmente.

---

## Controle de qualidade (número de medidas)

| Parâmetro | Referência |
|---|---|
| Total ideal de medidas brutas | 24 a 36 |
| Mínimo de medidas válidas aceitas | 14 a 18 |

- Se medidas válidas < 14: **exame inválido** — sinalizar e não emitir média.
- Se medidas válidas entre 14–17: **sinalizar** que o exame está no limite inferior de qualidade.
- Se medidas válidas ≥ 18: exame com qualidade adequada.

---

## Observações

- Manter formatação compacta e escaneável na saída.
- Sempre informar quantas medidas foram excluídas e por qual critério.
- Em caso de leitura manuscrita ambígua, sinalizar o valor e prosseguir com a melhor leitura possível.
