# Servico-Subir-Arquivo

Este projeto é um **serviço do Windows** desenvolvido em **Delphi** que monitora uma pasta em rede e copia automaticamente **novos arquivos** para uma pasta em outro local. Ele foi criado para manter **históricos de versões anteriores** dos arquivos, evitando a perda causada pela sobrescrição frequente no diretório de origem.

## 💡 Motivação

Alguns sistemas geram arquivos automaticamente e substituem os existentes, o que causa perda de versões anteriores. Este serviço garante que cada novo arquivo seja copiado para uma pasta em rede antes que seja sobrescrito, funcionando como um **backup incremental simples e automatizado**.

## ⚙️ Como funciona

- O serviço monitora continuamente uma **pasta de origem** configurada.
- Sempre que detecta um **arquivo novo ou alterado**, copia esse arquivo para uma pasta de rede pré-definida.
- Para cada arquivo, ele cria subpastas com o nome anterior, salvando os últimos arquivos.
- Pode ser executado como **serviço do Windows**, garantindo funcionamento em segundo plano, mesmo sem um usuário logado.

## 🛠️ Tecnologias utilizadas

- **Delphi (Object Pascal)**
- **Windows Services**
- **File System Monitoring**
- **Rotinas de cópia de arquivos e manipulação de diretórios**

