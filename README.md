# Gestão de Cosméticos MVP — Controle de Pronta-Entrega e Validade

Aplicação web mobile-first desenvolvida em **Python / Django** para apoiar revendedoras autônomas de cosméticos e perfumaria multimarcas em **Londrina - PR** no controle de estoque a pronta-entrega, registro rápido de vendas, acompanhamento de encomendas da revista e alertas preventivos de vencimento.

Alinhado ao **Objetivo de Desenvolvimento Sustentável 8 (ODS 8 — Meta 8.3)**, o sistema promove a organização financeira, a redução de perdas de mercadorias e a inclusão digital de microempreendedoras informais.

---

## Funcionalidades Principais (MVP)

- **Tela 1 — Painel Inicial Mobile:** Resumo do estoque a pronta-entrega, atalhos prioritários em coluna única e listagem rápida de produtos disponíveis.
- **Tela 2 — Registro de Venda com Baixa Automática:** Seleção de cosmético, validação de saldo disponível, cálculo automático do valor total e lucro, e baixa imediata no estoque.
- **Tela 3 — Alertas de Validade, Encomendas e Resultados:** Confirmação visual da venda, alertas redundantes (ícone + texto + alto contraste) para produtos próximos do vencimento e controle de status de encomendas da revista.

---

## Acessibilidade e Inclusão (RNF04)

Projetado especificamente para usuárias com familiaridade básica em smartphones e uso sob iluminação externa:
- Tipografia ampliada (`>= 16 px` no corpo e rótulos).
- Contraste mínimo de `4,5:1` entre texto e fundo.
- Áreas de toque ampliadas (`>= 44x44 px`) e botões em coluna única.
- Sinalização redundante (ícones, badges textuais e cores) para evitar dependência exclusiva de cor.

---

## Arquitetura e Tecnologias

- **Linguagem e Framework:** Python 3.12 + Django 5.1
- **Banco de Dados:** SQLite (desenvolvimento/MVP) com ORM Django
- **Frontend:** HTML5, CSS3 e Bootstrap 5 (mobile-first)
- **Segurança:** Autenticação com hash PBKDF2, proteção anti-CSRF nativa e validação server-side
- **Qualidade e CI:** Testes unitários e de integração (`manage.py test`) automatizados via GitHub Actions

---

## Como Executar Localmente

```bash
# 1. Clonar o repositório
git clone [https://github.com/naymauren/gestao-cosmeticos-mvp.git](https://github.com/naymauren/gestao-cosmeticos-mvp.git)
cd gestao-cosmeticos-mvp

# 2. Criar e ativar o ambiente virtual
python -m venv venv
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# 3. Instalar dependências
pip install -r requirements.txt

# 4. Aplicar migrações e popular dados iniciais fictícios
python manage.py migrate
python manage.py seed_dados

# 5. Executar testes automatizados
python manage.py test

# 6. Iniciar o servidor local
python manage.py runserver
