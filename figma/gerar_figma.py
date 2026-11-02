"""Gera um board SVG do spokfin (capa + design system + telas) para importar no Figma.

Uso: python gerar_figma.py <pasta_saida>
Cada tela também sai como SVG separado (390x844).
"""
import os
import sys
from xml.sax.saxutils import escape

BG = "#04090D"
SURFACE = "#0D1520"
SUNKEN = "#0A1119"
BORDER = "#1B2533"
HAIR = "#FFFFFF"  # usado com opacidade 0.08
PRIMARY = "#2563EB"
PRIMARY_S = "#1D4ED8"
ACCENT = "#4ADE80"
ACCENT_S = "#22C55E"
NEG = "#FB7185"
TXT = "#F5F7FA"
MUTED = "#6B7A8F"
CHART = ["#60A5FA", "#FBBF24", "#A78BFA", "#5EEAD4", "#FB7185"]
FONT = "Inter, sans-serif"

ICONES = {
    "home": ['<path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>', '<path d="M9 22V12h6v10"/>'],
    "chart": ['<path d="M12 20V10"/>', '<path d="M18 20V4"/>', '<path d="M6 20v-4"/>'],
    "repeat": ['<path d="M21 12a9 9 0 1 1-3-6.7L21 8"/>', '<path d="M21 3v5h-5"/>'],
    "receipt": ['<path d="M4 2v20l2-1 2 1 2-1 2 1 2-1 2 1 2-1 2 1V2l-2 1-2-1-2 1-2-1-2 1-2-1-2 1Z"/>', '<path d="M16 8H8"/>', '<path d="M16 12H8"/>', '<path d="M13 16H8"/>'],
    "users": ['<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>', '<circle cx="9" cy="7" r="4"/>', '<path d="M22 21v-2a4 4 0 0 0-3-3.87"/>', '<path d="M16 3.13a4 4 0 0 1 0 7.75"/>'],
    "mic": ['<rect x="9" y="2" width="6" height="13" rx="3"/>', '<path d="M19 10v2a7 7 0 0 1-14 0v-2"/>', '<path d="M12 19v3"/>'],
    "pen": ['<path d="M12 20h9"/>', '<path d="M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4Z"/>'],
    "plus": ['<path d="M12 5v14"/>', '<path d="M5 12h14"/>'],
    "alert": ['<path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/>', '<path d="M12 9v4"/>', '<path d="M12 17h.01"/>'],
    "search": ['<circle cx="11" cy="11" r="8"/>', '<path d="m21 21-4.3-4.3"/>'],
    "back": ['<path d="m15 18-6-6 6-6"/>'],
    "check": ['<path d="M20 6 9 17l-5-5"/>'],
    "spark": ['<path d="M12 3l1.9 5.8L20 10l-6.1 1.2L12 17l-1.9-5.8L4 10l6.1-1.2z"/>'],
    "download": ['<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>', '<path d="m7 10 5 5 5-5"/>', '<path d="M12 15V3"/>'],
    "calendar": ['<rect x="3" y="4" width="18" height="18" rx="2"/>', '<path d="M16 2v4"/>', '<path d="M8 2v4"/>', '<path d="M3 10h18"/>'],
    "down": ['<path d="m6 9 6 6 6-6"/>'],
    "x": ['<path d="M18 6 6 18"/>', '<path d="m6 6 12 12"/>'],
    "pix": ['<path d="M12 2 2 12l10 10 10-10Z"/>', '<path d="m7 12 5-5 5 5-5 5Z"/>'],
}


def esc(s):
    return escape(str(s))


class Tela:
    def __init__(self, nome, w=390, h=844):
        self.nome, self.w, self.h = nome, w, h
        self.el = []

    def add(self, s):
        self.el.append(s)

    def rect(self, x, y, w, h, fill, rx=0, stroke=None, sw=1, op=None, nome=None):
        a = f' id="{esc(nome)}"' if nome else ""
        st = f' stroke="{stroke}" stroke-width="{sw}"' if stroke else ""
        o = f' fill-opacity="{op}"' if op is not None else ""
        self.add(f'<rect{a} x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}"{o}{st}/>')

    def text(self, x, y, s, size=14, fill=TXT, weight=400, anchor="start", ls=None, op=None):
        l = f' letter-spacing="{ls}"' if ls is not None else ""
        o = f' fill-opacity="{op}"' if op is not None else ""
        self.add(
            f'<text x="{x}" y="{y}" font-family="{FONT}" font-size="{size}" font-weight="{weight}" '
            f'fill="{fill}" text-anchor="{anchor}"{l}{o}>{esc(s)}</text>'
        )

    def icone(self, nome, x, y, size=20, cor=TXT, sw=2):
        k = size / 24
        partes = "".join(ICONES[nome])
        self.add(
            f'<g id="icon/{nome}" transform="translate({x} {y}) scale({k})" fill="none" stroke="{cor}" '
            f'stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round">{partes}</g>'
        )

    def linha(self, x1, y1, x2, y2, cor=HAIR, op=0.08, sw=1):
        self.add(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{cor}" stroke-opacity="{op}" stroke-width="{sw}"/>')

    def grupo(self, nome):
        self.add(f'<g id="{esc(nome)}">')

    def fim(self):
        self.add("</g>")

    def svg_interno(self):
        return (
            f'<rect width="{self.w}" height="{self.h}" fill="{BG}"/>'
            + "".join(self.el)
        )

    def svg(self):
        return (
            f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.w}" height="{self.h}" '
            f'viewBox="0 0 {self.w} {self.h}">' + self.svg_interno() + "</svg>"
        )


# ---------- blocos reutilizados ----------

def status_bar(t):
    t.text(24, 30, "9:41", 15, TXT, 600)
    t.rect(330, 20, 24, 12, "none", 3, TXT, 1.2)
    t.rect(332, 22, 17, 8, TXT, 1.5)
    t.rect(298, 24, 4, 8, TXT, 1)
    t.rect(304, 22, 4, 10, TXT, 1)
    t.rect(310, 20, 4, 12, TXT, 1)
    t.rect(316, 18, 4, 14, TXT, 1)


def nav(t, ativo):
    itens = [("home", "Home"), ("chart", "Balanço"), ("repeat", "MRR"), ("receipt", "Histórico"), ("users", "Clientes")]
    t.grupo("Navegação flutuante")
    x0, y0, w, h = 16, 768, 358, 64
    t.add(f'<rect x="{x0}" y="{y0+6}" width="{w}" height="{h}" rx="32" fill="#000" fill-opacity="0.35"/>')
    t.rect(x0, y0, w, h, SURFACE, 32, BORDER)
    cw = (w - 16) / 5
    for i, (ic, rot) in enumerate(itens):
        cx = x0 + 8 + cw * i
        ativo_i = i == ativo
        if ativo_i:
            t.rect(cx + 2, y0 + 8, cw - 4, h - 16, PRIMARY, 14)
        cor = TXT if ativo_i else MUTED
        t.icone(ic, cx + cw / 2 - 10, y0 + 14, 20, cor)
        t.text(cx + cw / 2, y0 + 48, rot, 10, cor, 600 if ativo_i else 500, "middle")
    t.fim()


def fab(t):
    t.grupo("FAB ações rápidas")
    t.add(f'<circle cx="342" cy="728" r="28" fill="{PRIMARY}"/>')
    t.icone("plus", 330, 716, 24, TXT, 2.4)
    t.fim()


def cabecalho(t, titulo, acao=None):
    status_bar(t)
    t.text(195, 82, titulo, 17, TXT, 700, "middle")
    if acao:
        largura = 20 + len(acao) * 8 + 16
        t.rect(374 - largura, 64, largura, 30, PRIMARY, 15)
        t.icone("plus", 374 - largura + 10, 71, 16, TXT)
        t.text(374 - largura + 30, 84, acao, 13, TXT, 600)


def card(t, x, y, w, h, rx=16, nome="Card"):
    t.rect(x, y, w, h, SURFACE, rx, BORDER, nome=nome)


def tile(t, x, y, w, desc, sub, valor, entrada, nf=False, separador=True):
    t.grupo(f"Lançamento / {desc}")
    t.text(x, y + 22, desc, 15, TXT, 600)
    t.text(x, y + 42, sub, 12, MUTED)
    if nf:
        sx = x + len(sub) * 6.2 + 8
        t.rect(sx, y + 30, 112, 17, "none", 8.5, PRIMARY)
        t.icone("receipt", sx + 7, y + 33, 10, PRIMARY, 2.4)
        t.text(sx + 21, y + 42, "NFC-e agendada", 10, PRIMARY, 600)
    sinal = "+" if entrada else "-"
    t.text(x + w, y + 32, f"{sinal}$ {valor}", 16, ACCENT if entrada else NEG, 700, "end")
    if separador:
        t.linha(x, y + 60, x + w, y + 60)
    t.fim()


def chip(t, x, y, rot, ativo=False, largura=None):
    w = largura or (len(rot) * 7.4 + 28)
    if ativo:
        t.rect(x, y, w, 32, PRIMARY, 16)
    else:
        t.rect(x, y, w, 32, SURFACE, 16, BORDER)
    t.text(x + w / 2, y + 21, rot, 13, TXT if ativo else MUTED, 600 if ativo else 500, "middle")
    return w


def rotulo(t, x, y, s, cor=MUTED):
    t.text(x, y, s, 11, cor, 500, ls=1.1)


# ---------- telas ----------

def tela_home():
    t = Tela("01 · Home")
    status_bar(t)
    t.text(20, 78, "spokfin", 20, TXT, 700, ls=-0.5)
    t.add(f'<circle cx="354" cy="72" r="16" fill="{SURFACE}" stroke="{HAIR}" stroke-opacity="0.08"/>')
    t.text(354, 76, "AL", 12, MUTED, 600, "middle")

    t.grupo("Card saldo")
    card(t, 16, 104, 358, 168, 24, "Card saldo bg")
    rotulo(t, 40, 140, "SALDO ATUAL")
    t.text(40, 186, "$ 8,430.50", 36, TXT, 700, ls=-0.5)
    t.text(40, 228, "A RECEBER", 11, MUTED)
    t.text(40, 252, "$ 2,150.00", 18, ACCENT, 700)
    t.text(199, 228, "A PAGAR", 11, MUTED)
    t.text(199, 252, "$ 640.00", 18, NEG, 700)
    t.fim()

    t.grupo("Vencendo em breve")
    card(t, 16, 288, 358, 150, 24, "Vencendo bg")
    t.icone("alert", 32, 302, 16, NEG)
    t.text(54, 314, "VENCENDO EM BREVE", 11, NEG, 700)
    tile(t, 32, 318, 326, "DAS MEI · Outubro", "Vence em 2 dias", "75.90", False)
    tile(t, 32, 378, 326, "Mensalidade · Studio Bloom", "Vence amanhã", "450.00", True, separador=False)
    t.fim()

    t.text(16, 476, "Lançamentos Recentes", 14, MUTED, 500)
    t.text(374, 476, "Ver tudo", 14, PRIMARY, 500, "end")
    y = 486
    dados = [
        ("Consultoria · João Pereira", "Hoje · Consultoria", "300.00", True, True),
        ("Adobe Creative Cloud", "Ontem · Ferramentas & Equipamentos", "124.00", False, False),
        ("Aula particular · Marina", "06/10 · Aula", "180.00", True, False),
    ]
    for i, d in enumerate(dados):
        tile(t, 16, y + i * 62, 358, *d, separador=i < len(dados) - 1)

    t.grupo("Barra de captura")
    t.rect(16, 760, 358, 60, SURFACE, 28)
    t.rect(24, 768, 112, 44, PRIMARY, 22)
    t.icone("mic", 44, 781, 18, TXT)
    t.text(68, 795, "Falar", 14, TXT, 700)
    t.icone("pen", 168, 781, 18, TXT)
    t.text(192, 795, "Anotar", 14, TXT, 400)
    t.icone("plus", 270, 781, 18, TXT)
    t.text(294, 795, "Manual", 14, TXT, 600)
    t.fim()
    return t


def tela_falar():
    t = Tela("02 · Falar (captura por voz)")
    status_bar(t)
    t.icone("x", 20, 62, 22, MUTED)
    t.text(195, 80, "Falar", 17, TXT, 700, "middle")
    rotulo(t, 195, 170, "ESCUTANDO...", ACCENT)
    # Transcrição em tempo real
    linhas = ["“Recebi 300 do João", "pela consultoria", "de ontem, já caiu no PIX”"]
    for i, l in enumerate(linhas):
        t.text(195, 236 + i * 38, l, 26, TXT if i < 2 else MUTED, 600, "middle", ls=-0.4)
    # Waveform
    t.grupo("Waveform")
    alturas = [10, 18, 30, 22, 44, 60, 38, 72, 54, 88, 64, 96, 70, 52, 80, 46, 62, 34, 50, 26, 40, 20, 28, 14, 18, 10]
    x0 = 195 - len(alturas) * 10 / 2
    for i, a in enumerate(alturas):
        t.rect(x0 + i * 10 + 2, 470 - a / 2, 5, a, ACCENT if 4 < i < 20 else MUTED, 2.5, op=1 if 4 < i < 20 else 0.5)
    t.fim()
    t.text(195, 560, "0:07", 15, MUTED, 500, "middle")
    t.text(195, 600, "Fale naturalmente — a IA preenche o resto.", 13, MUTED, 400, "middle")
    t.grupo("Botão gravar")
    t.add(f'<circle cx="195" cy="690" r="52" fill="{PRIMARY}" fill-opacity="0.18"/>')
    t.add(f'<circle cx="195" cy="690" r="38" fill="{PRIMARY}"/>')
    t.rect(181, 676, 28, 28, TXT, 6)
    t.fim()
    t.rect(16, 772, 358, 52, SURFACE, 26, BORDER)
    t.icone("check", 144, 788, 20, TXT)
    t.text(170, 803, "Concluir", 15, TXT, 600)
    return t


def campo(t, x, y, w, rot, valor, cor=TXT, icone=None, ia=False):
    rotulo(t, x, y, rot)
    t.rect(x, y + 10, w, 48, SURFACE, 12, PRIMARY if ia else BORDER, 1)
    ox = x + 14
    if icone:
        t.icone(icone, ox, y + 24, 18, MUTED)
        ox += 28
    t.text(ox, y + 39, valor, 15, cor, 500)
    if ia:
        t.icone("spark", x + w - 30, y + 24, 16, PRIMARY)


def tela_revisar():
    t = Tela("03 · Revisar lançamento (IA)")
    status_bar(t)
    t.icone("back", 16, 66, 22, TXT)
    t.text(195, 82, "Revisar Lançamento", 17, TXT, 700, "middle")

    t.grupo("Aviso IA")
    t.rect(16, 108, 358, 64, PRIMARY, 14, op=0.12)
    t.rect(16, 108, 358, 64, "none", 14, PRIMARY, 1)
    t.icone("spark", 30, 122, 18, PRIMARY)
    t.text(56, 135, "Preenchido pela IA a partir da sua fala.", 13, TXT, 600)
    t.text(56, 155, "Confira antes de salvar — nada é gravado sem você.", 12, MUTED)
    t.fim()

    t.grupo("Seletor de tipo")
    t.rect(16, 188, 358, 44, SURFACE, 22, BORDER)
    t.rect(20, 192, 175, 36, ACCENT, 18, op=0.16)
    t.text(107, 215, "Entrada (Receber)", 13, ACCENT, 700, "middle")
    t.text(284, 215, "Saída (Pagar)", 13, MUTED, 500, "middle")
    t.fim()

    rotulo(t, 16, 262, "VALOR")
    t.text(16, 304, "$ 300.00", 34, ACCENT, 700, ls=-0.5)
    campo(t, 16, 336, 358, "DESCRIÇÃO", "Consultoria", ia=True)
    campo(t, 16, 412, 358, "CATEGORIA", "Consultoria", ia=True)
    campo(t, 16, 488, 358, "CLIENTE", "João Pereira", icone="users", ia=True)
    campo(t, 16, 564, 171, "DATA", "07/10/2026", icone="calendar", ia=True)
    rotulo(t, 203, 564, "STATUS")
    t.rect(203, 574, 171, 48, SURFACE, 12, BORDER)
    t.rect(211, 582, 76, 32, ACCENT, 10, op=0.16)
    t.text(249, 603, "Pago", 13, ACCENT, 700, "middle")
    t.text(330, 603, "Pendente", 13, MUTED, 500, "middle")

    t.grupo("Nota fiscal")
    t.rect(16, 642, 358, 52, SURFACE, 12, BORDER)
    t.text(30, 673, "Emitir Nota Fiscal (NFC-e)?", 14, TXT, 500)
    t.rect(318, 656, 44, 24, PRIMARY, 12)
    t.add(f'<circle cx="350" cy="668" r="9" fill="{TXT}"/>')
    t.fim()

    t.grupo("Ações")
    t.rect(16, 716, 358, 54, PRIMARY, 27)
    t.text(195, 749, "Confirmar Lançamento", 15, TXT, 700, "middle")
    t.text(195, 802, "Cancelar", 14, MUTED, 500, "middle")
    t.fim()
    return t


def tela_balanco():
    t = Tela("04 · Balanço")
    cabecalho(t, "Balancete Mensal")
    x = 16
    for i, rot in enumerate(["Outubro", "Setembro", "Todos os meses"]):
        x += chip(t, x, 108, rot, i == 0) + 8

    t.grupo("KPIs")
    card(t, 16, 156, 358, 104, 16)
    rotulo(t, 32, 184, "LUCRO LÍQUIDO")
    t.text(32, 222, "$ 3,842.00", 28, ACCENT, 700, ls=-0.4)
    t.text(32, 246, "▲ 12% vs. setembro", 12, ACCENT, 500)
    card(t, 16, 272, 173, 76, 16)
    rotulo(t, 30, 298, "FATURAMENTO")
    t.text(30, 330, "$ 5,920.00", 18, ACCENT, 700)
    card(t, 201, 272, 173, 76, 16)
    rotulo(t, 215, 298, "CUSTOS")
    t.text(215, 330, "$ 2,078.00", 18, NEG, 700)
    t.fim()

    t.grupo("Entradas vs saídas")
    card(t, 16, 360, 358, 196, 16)
    rotulo(t, 32, 388, "ENTRADAS VS SAÍDAS")
    base = 530
    semanas = [(1180, 420), (1620, 690), (1340, 380), (1780, 588)]
    for i, (e, s) in enumerate(semanas):
        cx = 52 + i * 82
        he, hs = e / 1800 * 110, s / 1800 * 110
        t.rect(cx, base - he, 18, he, ACCENT, 4)
        t.rect(cx + 22, base - hs, 18, hs, NEG, 4)
        t.text(cx + 20, base + 18, f"S{i+1}", 11, MUTED, 500, "middle")
    t.linha(32, base, 358, base)
    t.add(f'<circle cx="250" cy="384" r="4" fill="{ACCENT}"/>')
    t.text(258, 388, "Entradas", 11, MUTED)
    t.add(f'<circle cx="314" cy="384" r="4" fill="{NEG}"/>')
    t.text(322, 388, "Saídas", 11, MUTED)
    t.fim()

    t.grupo("Gastos por categoria")
    card(t, 16, 568, 358, 184, 16)
    rotulo(t, 32, 596, "GASTOS POR CATEGORIA")
    cats = [("Fornecedores", 0.38), ("Impostos & DAS", 0.22), ("Ferramentas", 0.2), ("Marketing", 0.12), ("Outros", 0.08)]
    import math
    cx, cy, r = 100, 676, 50
    circ = 2 * math.pi * r
    acc = 0
    for i, (_, p) in enumerate(cats):
        t.add(
            f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{CHART[i]}" stroke-width="18" '
            f'stroke-dasharray="{p*circ-3:.1f} {circ:.1f}" stroke-dashoffset="{-acc*circ:.1f}" transform="rotate(-90 {cx} {cy})"/>'
        )
        acc += p
    for i, (n, p) in enumerate(cats):
        y = 626 + i * 24
        t.rect(184, y - 9, 10, 10, CHART[i], 3)
        t.text(202, y, n, 12, TXT, 500)
        t.text(358, y, f"{int(p*100)}%", 12, MUTED, 500, "end")
    t.fim()
    nav(t, 1)
    return t


def tela_mrr():
    t = Tela("05 · MRR (assinaturas)")
    cabecalho(t, "Assinantes Mensais", "Nova")
    t.grupo("Card MRR")
    card(t, 16, 108, 358, 128, 24)
    rotulo(t, 40, 142, "MRR")
    t.text(40, 188, "$ 2,340.00", 34, ACCENT, 700, ls=-0.5)
    t.text(40, 214, "/mês", 12, MUTED)
    rotulo(t, 260, 142, "ATIVOS")
    t.text(260, 188, "8", 34, TXT, 700)
    t.fim()
    subs = [
        ("Studio Bloom", "Vence dia 10", "450.00", "Atrasado", NEG),
        ("Café Aurora", "Vence dia 12", "380.00", "Pendente", "#FBBF24"),
        ("Clínica Viver", "Vence dia 05", "320.00", "Pago", ACCENT),
        ("Ana Ribeiro", "Vence dia 03", "290.00", "Pago", ACCENT),
        ("Barbearia Norte", "Vence dia 01", "250.00", "Pago", ACCENT),
        ("Loja Ateliê 22", "Vence dia 15", "220.00", "Pendente", "#FBBF24"),
    ]
    y = 256
    for i, (n, sub, v, st, cor) in enumerate(subs):
        t.grupo(f"Assinatura / {n}")
        ini = "".join(p[0] for p in n.split()[:2]).upper()
        t.add(f'<circle cx="38" cy="{y+28}" r="20" fill="{SURFACE}" stroke="{BORDER}"/>')
        t.text(38, y + 32, ini, 12, MUTED, 600, "middle")
        t.text(70, y + 24, n, 15, TXT, 600)
        t.text(70, y + 43, sub, 12, MUTED)
        t.text(374, y + 24, f"$ {v}", 15, TXT, 700, "end")
        w = len(st) * 6.6 + 18
        t.rect(374 - w, y + 32, w, 20, cor, 10, op=0.14)
        t.text(374 - w / 2, y + 46, st, 11, cor, 600, "middle")
        if i < len(subs) - 1:
            t.linha(70, y + 64, 374, y + 64)
        t.fim()
        y += 74
    nav(t, 2)
    fab(t)
    return t


def tela_historico():
    t = Tela("06 · Histórico")
    cabecalho(t, "Histórico de Contas")
    t.grupo("Busca")
    t.rect(16, 108, 358, 44, SURFACE, 22, BORDER)
    t.icone("search", 32, 120, 18, MUTED)
    t.text(60, 135, "Buscar lançamentos...", 14, MUTED)
    t.fim()
    x = 16
    for i, rot in enumerate(["Todos", "Entradas", "Saídas", "Outubro"]):
        x += chip(t, x, 164, rot, i == 0) + 8
    t.icone("down", x - 30, 172, 16, MUTED)
    t.grupo("Exportar")
    t.rect(16, 210, 358, 44, SUNKEN, 12, BORDER)
    t.icone("download", 32, 222, 18, PRIMARY)
    t.text(60, 237, "Exportar período em PDF", 14, PRIMARY, 600)
    t.fim()
    grupos = [
        ("HOJE", [("Consultoria · João Pereira", "Consultoria · Pago", "300.00", True, True)]),
        ("ONTEM", [("Adobe Creative Cloud", "Ferramentas · Pago", "124.00", False, False),
                   ("Venda · Kit identidade visual", "Venda · Pendente", "890.00", True, False)]),
        ("05/10", [("Aluguel coworking", "Aluguel & Infraestrutura · Pago", "350.00", False, False),
                   ("Aula particular · Marina", "Aula · Pago", "180.00", True, False),
                   ("Meta Ads", "Marketing & Anúncios · Atrasado", "60.00", False, False)]),
    ]
    y = 286
    for g, itens in grupos:
        rotulo(t, 16, y, g)
        y += 4
        for i, it in enumerate(itens):
            tile(t, 16, y, 358, *it, separador=i < len(itens) - 1)
            y += 62
        y += 22
    nav(t, 3)
    fab(t)
    return t


def tela_clientes():
    t = Tela("07 · Clientes e Fornecedores")
    cabecalho(t, "Clientes e Devedores", "Novo")
    t.grupo("Segmento")
    t.rect(16, 108, 358, 40, SURFACE, 20, BORDER)
    t.rect(20, 112, 175, 32, PRIMARY, 16)
    t.text(107, 133, "Clientes", 13, TXT, 600, "middle")
    t.text(284, 133, "Fornecedores", 13, MUTED, 500, "middle")
    t.fim()
    t.rect(16, 160, 358, 44, SURFACE, 22, BORDER)
    t.icone("search", 32, 172, 18, MUTED)
    t.text(60, 187, "Buscar cliente por nome...", 14, MUTED)
    cli = [
        ("João Pereira", "Último: hoje", "Deve $ 600.00", NEG, True),
        ("Studio Bloom", "Último: 10/09", "Deve $ 450.00", NEG, True),
        ("Marina Costa", "Último: 06/10", "Em dia", ACCENT, False),
        ("Café Aurora", "Último: 12/09", "Deve $ 380.00", NEG, True),
        ("Clínica Viver", "Último: 05/10", "Em dia", ACCENT, False),
        ("Rafael Lima", "Sem lançamentos", "—", MUTED, False),
    ]
    y = 220
    for i, (n, sub, st, cor, _) in enumerate(cli):
        t.grupo(f"Cliente / {n}")
        ini = "".join(p[0] for p in n.split()[:2]).upper()
        t.add(f'<circle cx="38" cy="{y+28}" r="20" fill="{PRIMARY}" fill-opacity="0.16"/>')
        t.text(38, y + 32, ini, 12, "#93B4FB", 700, "middle")
        t.text(70, y + 24, n, 15, TXT, 600)
        t.text(70, y + 43, sub, 12, MUTED)
        t.text(374, y + 34, st, 13, cor, 700 if cor == NEG else 500, "end")
        if i < len(cli) - 1:
            t.linha(70, y + 64, 374, y + 64)
        t.fim()
        y += 74
    nav(t, 4)
    fab(t)
    return t


# ---------- board ----------

def board(telas, saida):
    W = 80 + 4 * 390 + 3 * 80 + 80  # 1960
    linhas = (len(telas) + 3) // 4
    topo = 760
    H = topo + linhas * (844 + 140) + 120
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">']
    out.append(f'<rect id="Board" width="{W}" height="{H}" fill="#070D13"/>')

    def T(x, y, s, size, fill=TXT, weight=400, anchor="start", ls=None):
        l = f' letter-spacing="{ls}"' if ls is not None else ""
        out.append(f'<text x="{x}" y="{y}" font-family="{FONT}" font-size="{size}" font-weight="{weight}" fill="{fill}" text-anchor="{anchor}"{l}>{esc(s)}</text>')

    # Capa
    out.append('<g id="Capa">')
    T(80, 110, "CASE · UI/UX · PRODUTO PRÓPRIO", 13, PRIMARY, 600, ls=2)
    T(80, 190, "spokfin", 72, TXT, 700, ls=-2)
    T(80, 240, "Gestão financeira para MEIs e autônomos — você fala, a IA lança.", 24, MUTED, 400)
    texto = [
        "Problema: quem trabalha sozinho não registra o que entra e sai porque preencher formulário campo a campo custa caro no dia a dia.",
        "Solução: o usuário fala ou digita em português natural (“recebi 300 do João pela consultoria”) e a IA extrai tipo, valor, categoria,",
        "cliente, data e status — abrindo uma tela de revisão já preenchida. Nada é salvo sem confirmação humana.",
    ]
    for i, l in enumerate(texto):
        T(80, 296 + i * 26, l, 16, TXT if i == 0 else "#B6C1CF", 400)
    tags = ["Flutter Web", "Supabase", "Google Gemini", "Dark UI", "Mobile-first", "PIX · CPF/CNPJ · LGPD"]
    x = 80
    for tg in tags:
        w = len(tg) * 8 + 32
        out.append(f'<rect x="{x}" y="390" width="{w}" height="34" rx="17" fill="{SURFACE}" stroke="{BORDER}"/>')
        T(x + w / 2, 412, tg, 13, TXT, 500, "middle")
        x += w + 10
    out.append("</g>")

    # Design system
    out.append('<g id="Design system">')
    T(80, 500, "DESIGN SYSTEM — “TRUST LEDGER”", 13, MUTED, 600, ls=2)
    cores = [
        ("Background", BG, "#04090D"), ("Surface", SURFACE, "#0D1520"), ("Border", BORDER, "#1B2533"),
        ("Primary · ação", PRIMARY, "#2563EB"), ("Accent · dinheiro", ACCENT, "#4ADE80"),
        ("Negative · saída", NEG, "#FB7185"), ("Text", TXT, "#F5F7FA"), ("Muted", MUTED, "#6B7A8F"),
    ]
    for i, (n, c, h) in enumerate(cores):
        x = 80 + i * 132
        out.append(f'<rect x="{x}" y="524" width="96" height="96" rx="16" fill="{c}" stroke="{BORDER}"/>')
        T(x, 644, n, 12, TXT, 600)
        T(x, 662, h, 12, MUTED, 400)
    tx = 1200
    T(tx, 548, "Aa  Inter", 34, TXT, 700)
    T(tx, 584, "36 Bold — saldo · 17 Bold — título · 15 Semibold — item", 14, MUTED)
    T(tx, 606, "13 Medium — botão · 12 Regular — apoio · 11 RÓTULO", 14, MUTED)
    regras = [
        "Azul = ação e navegação. Verde = dinheiro positivo e “pago”. Nunca os dois no mesmo elemento.",
        "Vermelho só para saída de dinheiro e erro — nunca decorativo.",
        "Elevação por camada tonal + borda sutil, não por sombra. Raios 12 · 16 · 24 · pílula.",
    ]
    for i, r in enumerate(regras):
        T(tx, 642 + i * 22, "•  " + r, 13, "#B6C1CF")
    out.append("</g>")

    for i, t in enumerate(telas):
        col, lin = i % 4, i // 4
        x = 80 + col * 470
        y = topo + 60 + lin * (844 + 140)
        T(x, y - 22, t.nome, 15, TXT, 600)
        out.append(f'<g id="{esc(t.nome)}" transform="translate({x} {y})">')
        out.append(f'<clipPath id="clip{i}"><rect width="390" height="844" rx="36"/></clipPath>')
        out.append(f'<g clip-path="url(#clip{i})">{t.svg_interno()}</g>')
        out.append(f'<rect width="390" height="844" rx="36" fill="none" stroke="{BORDER}" stroke-width="2"/>')
        out.append("</g>")

    # Notas de decisão ao lado da última linha
    idx = len(telas)
    col, lin = idx % 4, idx // 4
    if col != 0:
        x = 80 + col * 470
        y = topo + 60 + lin * (844 + 140)
        out.append('<g id="Decisões de UX">')
        out.append(f'<rect x="{x}" y="{y}" width="390" height="844" rx="24" fill="{SURFACE}" stroke="{BORDER}"/>')
        T(x + 28, y + 52, "DECISÕES DE UX", 12, PRIMARY, 600, ls=2)
        notas = [
            ("Voz como entrada principal", ["“Falar” é o botão de maior peso", "na Home: o caminho comum", "não exige digitar nada."]),
            ("Humano no controle", ["A IA só preenche. A tela de", "revisão marca cada campo", "inferido e exige confirmação."]),
            ("Cor com significado", ["Verde e vermelho falam só de", "dinheiro; azul fala só de ação.", "Lê-se o estado num relance."]),
            ("Urgência primeiro", ["Contas vencendo aparecem", "acima do histórico, logo", "depois do saldo."]),
            ("Contexto brasileiro", ["PIX, CPF/CNPJ com validação", "real, NFC-e e LGPD", "(exclusão de conta)."]),
        ]
        yy = y + 100
        for tit, ls in notas:
            T(x + 28, yy, tit, 17, TXT, 700)
            for j, l in enumerate(ls):
                T(x + 28, yy + 26 + j * 21, l, 14, "#B6C1CF")
            yy += 140
        out.append("</g>")

    out.append("</svg>")
    with open(os.path.join(saida, "spokfin-board.svg"), "w", encoding="utf-8") as f:
        f.write("".join(out))


def main():
    saida = sys.argv[1]
    os.makedirs(os.path.join(saida, "telas"), exist_ok=True)
    telas = [tela_home(), tela_falar(), tela_revisar(), tela_balanco(), tela_mrr(), tela_historico(), tela_clientes()]
    for t in telas:
        nome = t.nome.split(" · ")[0] + "-" + t.nome.split(" · ")[1].split(" (")[0].lower().replace(" ", "-")
        with open(os.path.join(saida, "telas", nome + ".svg"), "w", encoding="utf-8") as f:
            f.write(t.svg())
    board(telas, saida)
    print("ok", len(telas))


main()
