# --- COMMIT 1: Estrutura base do projeto Django e dependencias ---
@"
Django>=5.1,<5.2
"@ | Set-Content -Encoding UTF8 requirements.txt

@"
venv/
__pycache__/
*.pyc
db.sqlite3
.DS_Store
"@ | Set-Content -Encoding UTF8 .gitignore

New-Item -ItemType Directory -Force -Path config, estoque, estoque\templates\estoque, estoque\management\commands, .github\workflows | Out-Null

@"
#!/usr/bin/env python
import os
import sys

def main():
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
    from django.core.management import execute_from_command_line
    execute_from_command_line(sys.argv)

if __name__ == '__main__':
    main()
"@ | Set-Content -Encoding UTF8 manage.py

"" | Set-Content -Encoding UTF8 config\__init__.py

@"
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
SECRET_KEY = 'django-insecure-mvp-cosmeticos-londrina-ods8'
DEBUG = True
ALLOWED_HOSTS = ['*']

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'estoque',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
]

LANGUAGE_CODE = 'pt-br'
TIME_ZONE = 'America/Sao_Paulo'
USE_I18N = True
USE_TZ = True
STATIC_URL = 'static/'
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
"@ | Set-Content -Encoding UTF8 config\settings.py

@"
import os
from django.core.wsgi import get_wsgi_application
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
application = get_wsgi_application()
"@ | Set-Content -Encoding UTF8 config\wsgi.py

@"
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('estoque.urls')),
]
"@ | Set-Content -Encoding UTF8 config\urls.py

git add .
git commit -m "chore: configura estrutura inicial do projeto Django e banco SQLite"

# --- COMMIT 2: Modelos de dados (Cosmetico, Venda e Encomenda) ---
"" | Set-Content -Encoding UTF8 estoque\__init__.py
"" | Set-Content -Encoding UTF8 estoque\management\__init__.py
"" | Set-Content -Encoding UTF8 estoque\management\commands\__init__.py

@"
from django.apps import AppConfig

class EstoqueConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'estoque'
"@ | Set-Content -Encoding UTF8 estoque\apps.py

@"
from datetime import date
from decimal import Decimal
from django.db import models
from django.core.exceptions import ValidationError


class Cosmetico(models.Model):
    nome = models.CharField(max_length=120)
    marca = models.CharField(max_length=60, default='Natura')
    preco_custo = models.DecimalField(max_digits=8, decimal_places=2)
    preco_venda = models.DecimalField(max_digits=8, decimal_places=2)
    quantidade_estoque = models.PositiveIntegerField(default=0)
    data_validade = models.DateField()

    class Meta:
        ordering = ['data_validade', 'nome']

    def dias_para_vencer(self):
        return (self.data_validade - date.today()).days

    def status_validade(self):
        dias = self.dias_para_vencer()
        if dias < 0:
            return 'Vencido'
        if dias <= 30:
            return 'Vence em breve'
        return 'Dentro do prazo'

    def __str__(self):
        return f"{self.nome} ({self.quantidade_estoque} un.)"


class Venda(models.Model):
    cosmetico = models.ForeignKey(Cosmetico, on_delete=models.PROTECT, related_name='vendas')
    quantidade = models.PositiveIntegerField()
    valor_total = models.DecimalField(max_digits=10, decimal_places=2, editable=False)
    lucro_estimado = models.DecimalField(max_digits=10, decimal_places=2, editable=False)
    data_venda = models.DateTimeField(auto_now_add=True)

    def clean(self):
        if self.quantidade <= 0:
            raise ValidationError('A quantidade vendida deve ser maior que zero.')
        if self.cosmetico_id and self.quantidade > self.cosmetico.quantidade_estoque:
            raise ValidationError('Saldo insuficiente em estoque para esta quantidade.')

    def save(self, *args, **kwargs):
        is_new = self.pk is None
        self.full_clean()
        self.valor_total = (self.cosmetico.preco_venda * Decimal(self.quantidade)).quantize(Decimal('0.01'))
        lucro_unit = self.cosmetico.preco_venda - self.cosmetico.preco_custo
        self.lucro_estimado = (lucro_unit * Decimal(self.quantidade)).quantize(Decimal('0.01'))
        super().save(*args, **kwargs)
        if is_new:
            self.cosmetico.quantidade_estoque -= self.quantidade
            self.cosmetico.save(update_fields=['quantidade_estoque'])


class Encomenda(models.Model):
    STATUS_CHOICES = [
        ('PEDIDO_FEITO', 'Pedido feito'),
        ('CHEGOU', 'Chegou'),
        ('ENTREGUE', 'Entregue'),
    ]
    cliente = models.CharField(max_length=100)
    produto_descricao = models.CharField(max_length=140)
    quantidade = models.PositiveIntegerField(default=1)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PEDIDO_FEITO')
    criado_em = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-criado_em']

    def __str__(self):
        return f"{self.cliente} - {self.produto_descricao}"
"@ | Set-Content -Encoding UTF8 estoque\models.py

@"
from django.contrib import admin
from .models import Cosmetico, Venda, Encomenda

admin.site.register(Cosmetico)
admin.site.register(Venda)
admin.site.register(Encomenda)
"@ | Set-Content -Encoding UTF8 estoque\admin.py

@"
from datetime import date, timedelta
from decimal import Decimal
from django.core.management.base import BaseCommand
from estoque.models import Cosmetico, Encomenda


class Command(BaseCommand):
    help = 'Popula dados ficticios iniciais para demonstracao e validacao do MVP'

    def handle(self, *args, **options):
        if not Cosmetico.objects.exists():
            Cosmetico.objects.create(
                nome='Sabonete em Barra Caixa com 5',
                marca='Natura Tododia',
                preco_custo=Decimal('18.00'),
                preco_venda=Decimal('28.90'),
                quantidade_estoque=2,
                data_validade=date.today() + timedelta(days=180),
            )
            Cosmetico.objects.create(
                nome='Protetor Solar Facial FPS 50',
                marca='Natura Fotoequilibrio',
                preco_custo=Decimal('32.00'),
                preco_venda=Decimal('49.90'),
                quantidade_estoque=2,
                data_validade=date.today() + timedelta(days=12),
            )
            Cosmetico.objects.create(
                nome='Hidratante Corporal 400ml',
                marca='O Boticario',
                preco_custo=Decimal('38.00'),
                preco_venda=Decimal('59.90'),
                quantidade_estoque=4,
                data_validade=date.today() + timedelta(days=240),
            )
        if not Encomenda.objects.exists():
            Encomenda.objects.create(
                cliente='Mariana Silva',
                produto_descricao='Batom Matte Vermelho',
                quantidade=1,
                status='PEDIDO_FEITO',
            )
        self.stdout.write(self.style.SUCCESS('Dados iniciais do MVP carregados com sucesso.'))
"@ | Set-Content -Encoding UTF8 estoque\management\commands\seed_dados.py

git add .
git commit -m "feat: modela entidades Cosmetico, Venda e Encomenda com baixa automatica de estoque"

# --- COMMIT 3: Views, rotas e regras de negocio das 3 telas ---
@"
from django.urls import path
from . import views

urlpatterns = [
    path('', views.painel_inicial, name='painel_inicial'),
    path('registrar-venda/', views.registrar_venda, name='registrar_venda'),
    path('resultados/<int:venda_id>/', views.alertas_resultados, name='alertas_resultados'),
    path('resultados/', views.alertas_resultados, name='alertas_gerais'),
]
"@ | Set-Content -Encoding UTF8 estoque\urls.py

@"
from datetime import date, timedelta
from django.core.exceptions import ValidationError
from django.db.models import Sum
from django.shortcuts import get_object_or_404, redirect, render
from .models import Cosmetico, Encomenda, Venda


def painel_inicial(request):
    cosmeticos = Cosmetico.objects.all()
    total_unidades = cosmeticos.aggregate(total=Sum('quantidade_estoque'))['total'] or 0
    limite_alerta = date.today() + timedelta(days=30)
    alertas_count = cosmeticos.filter(data_validade__lte=limite_alerta, quantidade_estoque__gt=0).count()
    return render(request, 'estoque/painel.html', {
        'cosmeticos': cosmeticos,
        'total_unidades': total_unidades,
        'alertas_count': alertas_count,
    })


def registrar_venda(request):
    cosmeticos = Cosmetico.objects.filter(quantidade_estoque__gt=0)
    erro = None
    selecionado_id = request.GET.get('produto') or request.POST.get('cosmetico')

    if request.method == 'POST':
        cosmetico_id = request.POST.get('cosmetico')
        quantidade_raw = request.POST.get('quantidade', '').strip()
        if not cosmetico_id or not quantidade_raw:
            erro = 'Selecione o cosmetico e informe a quantidade vendida.'
        else:
            try:
                quantidade = int(quantidade_raw)
                cosmetico = get_object_or_404(Cosmetico, pk=cosmetico_id)
                venda = Venda(cosmetico=cosmetico, quantidade=quantidade)
                venda.save()
                return redirect('alertas_resultados', venda_id=venda.id)
            except ValueError:
                erro = 'Informe uma quantidade numerica valida.'
            except ValidationError as exc:
                erro = '; '.join(exc.messages)

    return render(request, 'estoque/registrar_venda.html', {
        'cosmeticos': cosmeticos,
        'erro': erro,
        'selecionado_id': str(selecionado_id or ''),
    })


def alertas_resultados(request, venda_id=None):
    venda = get_object_or_404(Venda, pk=venda_id) if venda_id else None
    limite_alerta = date.today() + timedelta(days=30)
    alertas = Cosmetico.objects.filter(data_validade__lte=limite_alerta, quantidade_estoque__gt=0)
    encomendas = Encomenda.objects.all()
    resumo_mes = Venda.objects.aggregate(
        faturamento=Sum('valor_total'),
        lucro=Sum('lucro_estimado'),
    )
    return render(request, 'estoque/resultados.html', {
        'venda': venda,
        'alertas': alertas,
        'encomendas': encomendas,
        'resumo_mes': resumo_mes,
    })
"@ | Set-Content -Encoding UTF8 estoque\views.py

git add .
git commit -m "feat: implementa fluxos e regras server-side das telas de painel, venda e alertas"

# --- COMMIT 4: Templates HTML mobile-first com acessibilidade (RNF04) ---
@"
<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}Gestao de Cosmeticos MVP{% endblock %}</title>
    <style>
        :root {
            --bg: #F8FAFC;
            --card: #FFFFFF;
            --text: #0F172A;
            --muted: #334155;
            --primary: #0F766E;
            --primary-dark: #115E59;
            --warning-bg: #FEF3C7;
            --warning-border: #B45309;
            --success-bg: #DCFCE7;
            --success-border: #15803D;
            --danger-bg: #FEE2E2;
            --danger-border: #B91C1C;
        }
        * { box-sizing: border-box; }
        body {
            margin: 0;
            font-family: system-ui, -apple-system, sans-serif;
            background: var(--bg);
            color: var(--text);
            font-size: 16px;
            line-height: 1.5;
        }
        .container { max-width: 480px; margin: 0 auto; padding: 16px; }
        header {
            background: var(--primary);
            color: #FFFFFF;
            padding: 16px;
            border-radius: 12px;
            margin-bottom: 16px;
        }
        header h1 { margin: 0; font-size: 20px; }
        .card {
            background: var(--card);
            border: 2px solid #CBD5E1;
            border-radius: 12px;
            padding: 16px;
            margin-bottom: 16px;
        }
        .btn {
            display: block;
            width: 100%;
            min-height: 48px;
            padding: 12px 16px;
            font-size: 18px;
            font-weight: 700;
            text-align: center;
            text-decoration: none;
            border-radius: 10px;
            border: 2px solid transparent;
            cursor: pointer;
            margin-bottom: 12px;
        }
        .btn-primary { background: var(--primary); color: #FFFFFF; }
        .btn-primary:hover { background: var(--primary-dark); }
        .btn-secondary { background: #FFFFFF; color: var(--text); border-color: #0F172A; }
        label { display: block; font-weight: 700; margin-bottom: 6px; font-size: 17px; }
        select, input {
            width: 100%;
            min-height: 48px;
            font-size: 18px;
            padding: 10px 12px;
            border: 2px solid #475569;
            border-radius: 8px;
            margin-bottom: 16px;
            background: #FFFFFF;
            color: var(--text);
        }
        .badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 6px;
            font-weight: 700;
            font-size: 15px;
        }
        .badge-ok { background: var(--success-bg); color: #14532D; border: 1px solid var(--success-border); }
        .badge-warn { background: var(--warning-bg); color: #78350F; border: 1px solid var(--warning-border); }
        .alert-box {
            padding: 14px;
            border-radius: 10px;
            margin-bottom: 16px;
            font-weight: 600;
            border-left: 6px solid;
        }
        .alert-success { background: var(--success-bg); border-color: var(--success-border); color: #14532D; }
        .alert-danger { background: var(--danger-bg); border-color: var(--danger-border); color: #7F1D1D; }
        .alert-warning { background: var(--warning-bg); border-color: var(--warning-border); color: #78350F; }
    </style>
</head>
<body>
    <main class="container">
        {% block content %}{% endblock %}
    </main>
</body>
</html>
"@ | Set-Content -Encoding UTF8 estoque\templates\estoque\base.html

@"
{% extends 'estoque/base.html' %}
{% block title %}Tela 1 - Painel Inicial Mobile{% endblock %}
{% block content %}
<header>
    <h1>Minha Pronta-Entrega</h1>
    <p style="margin:4px 0 0;">Controle rapido de cosmeticos</p>
</header>

<section class="card" aria-label="Resumo do estoque">
    <p style="margin:0 0 8px;"><strong>Total em estoque:</strong> {{ total_unidades }} unidades</p>
    <p style="margin:0;"><strong>Alertas de validade:</strong> {{ alertas_count }} produto(s)</p>
</section>

<a href="{% url 'registrar_venda' %}" class="btn btn-primary">+ Registrar Venda</a>
<a href="{% url 'alertas_gerais' %}" class="btn btn-secondary">Ver Alertas e Encomendas</a>

<section aria-label="Cosmeticos disponiveis">
    <h2 style="font-size:18px;">Cosmeticos a Pronta-Entrega</h2>
    {% for item in cosmeticos %}
    <article class="card">
        <h3 style="margin:0 0 6px; font-size:18px;">{{ item.nome }}</h3>
        <p style="margin:0 0 6px;">Preco: <strong>R$ {{ item.preco_venda }}</strong> | Disponivel: <strong>{{ item.quantidade_estoque }} un.</strong></p>
        {% if item.dias_para_vencer <= 30 %}
            <span class="badge badge-warn">Atencao: vence em {{ item.dias_para_vencer }} dias</span>
        {% else %}
            <span class="badge badge-ok">OK: dentro do prazo</span>
        {% endif %}
    </article>
    {% empty %}
    <p>Nenhum cosmetico cadastrado.</p>
    {% endfor %}
</section>
{% endblock %}
"@ | Set-Content -Encoding UTF8 estoque\templates\estoque\painel.html

@"
{% extends 'estoque/base.html' %}
{% block title %}Tela 2 - Registro de Venda{% endblock %}
{% block content %}
<header>
    <h1>Registrar Venda</h1>
    <p style="margin:4px 0 0;">Baixa automatica no estoque</p>
</header>

<a href="{% url 'painel_inicial' %}" class="btn btn-secondary">&larr; Voltar ao Menu</a>

{% if erro %}
<div class="alert-box alert-danger" role="alert">
    <strong>Erro:</strong> {{ erro }}
</div>
{% endif %}

<form method="post" class="card">
    {% csrf_token %}
    <label for="cosmetico">Cosmetico vendido:</label>
    <select name="cosmetico" id="cosmetico" required>
        <option value="">Selecione um produto...</option>
        {% for item in cosmeticos %}
        <option value="{{ item.id }}" {% if selecionado_id == item.id|stringformat:"s" %}selected{% endif %}>
            {{ item.nome }} - R$ {{ item.preco_venda }} ({{ item.quantidade_estoque }} un.)
        </option>
        {% endfor %}
    </select>

    <label for="quantidade">Quantidade vendida:</label>
    <input type="number" name="quantidade" id="quantidade" min="1" inputmode="numeric" placeholder="Ex.: 1" required>

    <button type="submit" class="btn btn-primary">Confirmar Venda</button>
</form>
{% endblock %}
"@ | Set-Content -Encoding UTF8 estoque\templates\estoque\registrar_venda.html

@"
{% extends 'estoque/base.html' %}
{% block title %}Tela 3 - Alertas e Resultados{% endblock %}
{% block content %}
<header>
    <h1>Alertas e Resultados</h1>
    <p style="margin:4px 0 0;">Acompanhamento de validade e pedidos</p>
</header>

{% if venda %}
<div class="alert-box alert-success" role="status">
    <strong>Venda confirmada!</strong><br>
    Produto: {{ venda.cosmetico.nome }} ({{ venda.quantidade }} un.)<br>
    Total recebido: R$ {{ venda.valor_total }} | Lucro estimado: R$ {{ venda.lucro_estimado }}
</div>
{% endif %}

<section class="card" aria-label="Alertas de validade">
    <h2 style="margin-top:0; font-size:18px;">Alertas de Validade (Proximos 30 dias)</h2>
    {% for alerta in alertas %}
    <div class="alert-box alert-warning">
        <strong>Atencao — Vence em {{ alerta.dias_para_vencer }} dias:</strong><br>
        {{ alerta.nome }} ({{ alerta.quantidade_estoque }} unidades em estoque)
    </div>
    {% empty %}
    <p>Nenhum produto proximo do vencimento.</p>
    {% endfor %}
</section>

<section class="card" aria-label="Controle de encomendas">
    <h2 style="margin-top:0; font-size:18px;">Controle de Encomendas da Revista</h2>
    {% for enc in encomendas %}
    <p style="border-bottom:1px solid #E2E8F0; padding-bottom:8px;">
        <strong>Cliente:</strong> {{ enc.cliente }}<br>
        <strong>Pedido:</strong> {{ enc.quantidade }}x {{ enc.produto_descricao }}<br>
        <span class="badge badge-warn">Status: {{ enc.get_status_display }}</span>
    </p>
    {% empty %}
    <p>Nenhuma encomenda registrada.</p>
    {% endfor %}
</section>

<a href="{% url 'painel_inicial' %}" class="btn btn-primary">Menu Inicial</a>
{% endblock %}
"@ | Set-Content -Encoding UTF8 estoque\templates\estoque\resultados.html

git add .
git commit -m "feat: cria interfaces HTML mobile-first com alto contraste, fonte >= 16px e sinalizacao redundante"

# --- COMMIT 5: Testes unitarios e de integracao automatizados ---
@"
from datetime import date, timedelta
from decimal import Decimal
from django.core.exceptions import ValidationError
from django.test import TestCase
from django.urls import reverse
from .models import Cosmetico, Encomenda, Venda


class CosmeticoModelTest(TestCase):
    def test_status_validade_alerta_e_normal(self):
        vencendo = Cosmetico.objects.create(
            nome='Protetor Solar Facial FPS 50',
            preco_custo=Decimal('32.00'),
            preco_venda=Decimal('49.90'),
            quantidade_estoque=2,
            data_validade=date.today() + timedelta(days=12),
        )
        normal = Cosmetico.objects.create(
            nome='Sabonete em Barra Caixa com 5',
            preco_custo=Decimal('18.00'),
            preco_venda=Decimal('28.90'),
            quantidade_estoque=2,
            data_validade=date.today() + timedelta(days=120),
        )
        self.assertEqual(vencendo.status_validade(), 'Vence em breve')
        self.assertEqual(normal.status_validade(), 'Dentro do prazo')

    def test_venda_realiza_baixa_automatica_e_calcula_lucro(self):
        item = Cosmetico.objects.create(
            nome='Sabonete em Barra Caixa com 5',
            preco_custo=Decimal('18.00'),
            preco_venda=Decimal('28.90'),
            quantidade_estoque=2,
            data_validade=date.today() + timedelta(days=90),
        )
        venda = Venda.objects.create(cosmetico=item, quantidade=1)
        item.refresh_from_db()
        self.assertEqual(item.quantidade_estoque, 1)
        self.assertEqual(venda.valor_total, Decimal('28.90'))
        self.assertEqual(venda.lucro_estimado, Decimal('10.90'))

    def test_bloqueia_venda_acima_do_estoque_disponivel(self):
        item = Cosmetico.objects.create(
            nome='Sabonete em Barra Caixa com 5',
            preco_custo=Decimal('18.00'),
            preco_venda=Decimal('28.90'),
            quantidade_estoque=1,
            data_validade=date.today() + timedelta(days=90),
        )
        with self.assertRaises(ValidationError):
            Venda.objects.create(cosmetico=item, quantidade=3)


class FluxoIntegracaoMVPTest(TestCase):
    def setUp(self):
        self.item = Cosmetico.objects.create(
            nome='Sabonete em Barra Caixa com 5',
            preco_custo=Decimal('18.00'),
            preco_venda=Decimal('28.90'),
            quantidade_estoque=2,
            data_validade=date.today() + timedelta(days=120),
        )
        self.alerta = Cosmetico.objects.create(
            nome='Protetor Solar Facial FPS 50',
            preco_custo=Decimal('32.00'),
            preco_venda=Decimal('49.90'),
            quantidade_estoque=2,
            data_validade=date.today() + timedelta(days=12),
        )
        Encomenda.objects.create(
            cliente='Mariana Silva',
            produto_descricao='Batom Matte Vermelho',
            quantidade=1,
            status='PEDIDO_FEITO',
        )

    def test_fluxo_completo_tres_telas_e_acessibilidade(self):
        resp_painel = self.client.get(reverse('painel_inicial'))
        self.assertEqual(resp_painel.status_code, 200)
        self.assertContains(resp_painel, 'Sabonete em Barra Caixa com 5')
        self.assertContains(resp_painel, 'font-size: 16px')

        resp_venda = self.client.post(reverse('registrar_venda'), {
            'cosmetico': self.item.id,
            'quantidade': 1,
        }, follow=True)
        self.assertEqual(resp_venda.status_code, 200)
        self.assertContains(resp_venda, 'Venda confirmada!')
        self.assertContains(resp_venda, 'Protetor Solar Facial FPS 50')
        self.assertContains(resp_venda, 'Mariana Silva')
"@ | Set-Content -Encoding UTF8 estoque\tests.py

git add .
git commit -m "test: adiciona testes unitarios e de integracao para baixa de estoque, validade e acessibilidade"

# --- COMMIT 6: Pipeline de Integracao Continua (GitHub Actions) ---
@"
name: CI - Build e Testes Automatizados MVP

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout do codigo
        uses: actions/checkout@v4

      - name: Configurar Python 3.12
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Instalar dependencias
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt

      - name: Verificar migracoes e executar testes automatizados
        run: |
          python manage.py makemigrations --check --dry-run
          python manage.py test -v 2
"@ | Set-Content -Encoding UTF8 .github\workflows\ci.yml

git add .
git commit -m "ci: configura workflow GitHub Actions para execucao automatica de build e testes"