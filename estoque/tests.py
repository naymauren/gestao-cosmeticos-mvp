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
