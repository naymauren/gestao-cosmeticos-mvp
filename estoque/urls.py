from django.urls import path
from . import views

urlpatterns = [
    path('', views.painel_inicial, name='painel_inicial'),
    path('registrar-venda/', views.registrar_venda, name='registrar_venda'),
    path('resultados/<int:venda_id>/', views.alertas_resultados, name='alertas_resultados'),
    path('resultados/', views.alertas_resultados, name='alertas_gerais'),
]
