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
