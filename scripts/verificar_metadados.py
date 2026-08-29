#!/usr/bin/env python3
"""Verificacoes rapidas antes de fazer deploy.

Apanha os erros que ja nos custaram ciclos:
  1. <description> acima de 255 caracteres
  2. API names com acentos ou caracteres invalidos
  3. fieldPermissions declaradas para campos obrigatorios

Correr a partir da raiz do projeto:
    python scripts/verificar_metadados.py
"""
import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
FORCE_APP = RAIZ / "force-app"
erros = []


def texto(caminho: Path) -> str:
    return caminho.read_text(encoding="utf-8")


# 1) descricoes acima do limite da plataforma
for f in FORCE_APP.rglob("*-meta.xml"):
    for m in re.finditer(r"<description>(.*?)</description>", texto(f), re.S):
        n = len(m.group(1))
        if n > 255:
            erros.append(f"[descricao {n}/255] {f.relative_to(RAIZ)}")

# 2) API names invalidos - so [A-Za-z0-9_], a comecar por letra
for f in FORCE_APP.rglob("fields/*.field-meta.xml"):
    m = re.search(r"<fullName>([^<]*)</fullName>", texto(f))
    if m and not re.fullmatch(r"[A-Za-z][A-Za-z0-9_]*__c", m.group(1)):
        erros.append(f"[api name invalido: {m.group(1)}] {f.relative_to(RAIZ)}")

# 3) FLS declarada para campos obrigatorios - a plataforma rejeita
obrigatorios = set()
for f in FORCE_APP.rglob("fields/*.field-meta.xml"):
    s = texto(f)
    if "<required>true</required>" in s:
        nome = re.search(r"<fullName>([^<]*)</fullName>", s).group(1)
        objeto = f.parent.parent.name          # .../objects/<Objeto>/fields/x.xml
        obrigatorios.add(f"{objeto}.{nome}")

for f in FORCE_APP.rglob("*.permissionset-meta.xml"):
    s = texto(f)
    for campo in sorted(obrigatorios):
        if f"<field>{campo}</field>" in s:
            erros.append(f"[FLS em campo obrigatorio: {campo}] {f.relative_to(RAIZ)}")

if erros:
    print("\n".join(erros))
    print(f"\n{len(erros)} problema(s). Corrigir antes do deploy.")
    sys.exit(1)

print("Sem problemas conhecidos. Pronto para deploy.")
