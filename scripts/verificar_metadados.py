#!/usr/bin/env python3
"""Verificacoes rapidas antes de fazer deploy.

Apanha os erros que ja nos custaram ciclos:
  1. <description> acima de 255 caracteres
  2. API names com acentos ou caracteres invalidos
  3. fieldPermissions declaradas para campos obrigatorios
"""
import glob, re, sys

erros = []

# 1) descricoes demasiado longas
for f in glob.glob("force-app/**/*-meta.xml", recursive=True):
    s = open(f, encoding="utf-8").read()
    for m in re.finditer(r"<description>(.*?)</description>", s, re.S):
        if len(m.group(1)) > 255:
            erros.append(f"[descricao {len(m.group(1))}/255] {f}")

# 2) API names invalidos
for f in glob.glob("force-app/**/fields/*.field-meta.xml", recursive=True):
    s = open(f, encoding="utf-8").read()
    m = re.search(r"<fullName>([^<]*)</fullName>", s)
    if m and not re.fullmatch(r"[A-Za-z][A-Za-z0-9_]*__c", m.group(1)):
        erros.append(f"[api name invalido: {m.group(1)}] {f}")

# 3) permissoes declaradas para campos obrigatorios
obrigatorios = set()
for f in glob.glob("force-app/**/fields/*.field-meta.xml", recursive=True):
    s = open(f, encoding="utf-8").read()
    if "<required>true</required>" in s:
        n = re.search(r"<fullName>([^<]*)</fullName>", s).group(1)
        obrigatorios.add(f"{f.split('/')[-3]}.{n}")
for f in glob.glob("force-app/**/*.permissionset-meta.xml", recursive=True):
    s = open(f, encoding="utf-8").read()
    for campo in obrigatorios:
        if f"<field>{campo}</field>" in s:
            erros.append(f"[FLS em campo obrigatorio: {campo}] {f}")

if erros:
    print("\n".join(erros))
    print(f"\n{len(erros)} problema(s). Corrigir antes do deploy.")
    sys.exit(1)
print("Sem problemas conhecidos. Pronto para deploy.")
