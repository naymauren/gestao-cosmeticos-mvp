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
