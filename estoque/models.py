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
