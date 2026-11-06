# NamedTrace

Module PowerShell pour créer et piloter des traces SQL Server Profiler nommées avec les procédures `sp_trace_*`. La connexion et la découverte d'instances s'appuient sur [dbatools](https://dbatools.io/).

## Structure du module

- `Public/` contient un fichier `.ps1` par commande exportée.
- `Private/` contient les fonctions d'assistance chargées à l'intérieur du module et non exportées.
- `NamedTrace.psm1` charge les scripts privés et publics; le manifeste définit les commandes exportées.

## Prérequis

- Windows PowerShell 5.1 ou PowerShell 7
- Le module `dbatools`
- Des droits SQL Server autorisant les opérations de trace (généralement `sysadmin`)
- Pour `Install-NamedTrace`, le dossier doit exister sur le serveur SQL et le compte de service SQL doit pouvoir y écrire.

Les commandes acceptent soit `-SqlInstance`, soit `-ComputerName`. Dans le second cas, `Find-DbaInstance` découvre les instances SQL actives et l'opération est exécutée sur chacune.

## Commandes

```powershell
Get-NamedTrace -SqlInstance 'sql01\prod' -TraceName 'AuditApp'
Install-NamedTrace -SqlInstance 'sql01\prod' -TraceName 'AuditApp' -Path 'D:\SqlTraces'
Start-NamedTrace -SqlInstance 'sql01\prod' -TraceName 'AuditApp'
Stop-NamedTrace -SqlInstance 'sql01\prod' -TraceName 'AuditApp'
Uninstall-NamedTrace -SqlInstance 'sql01\prod' -TraceName 'AuditApp'

Move-NamedTraceFile -SqlInstance 'sql01\prod' -TraceName 'AuditApp' `
    -Destination '\\files01\SqlTraces'
Export-NamedTraceFile -SqlInstance 'sql02\reader' `
    -Path '\\files01\SqlTraces\AuditApp.trc' |
    Export-Csv '.\AuditApp.csv' -NoTypeInformation
```

`TraceName` correspond au nom de base du fichier `.trc` (sans extension); `Path` dans `Install-NamedTrace` est le dossier local sur l'instance SQL. `Install-NamedTrace` crée une trace arrêtée, à démarrer séparément. Elle capture les événements `RPC:Completed`, `SQL:BatchCompleted` et `Exception`, avec les colonnes Profiler usuelles (texte, base, login, application, durée et ressources). Les fichiers sont configurés avec rollover (100 Mo, jusqu'à 5 fichiers).

`Uninstall-NamedTrace` ferme la définition SQL mais ne supprime pas les fichiers `.trc`. `Move-NamedTraceFile` ferme la trace pour libérer les fichiers, déplace les fichiers principaux et rollover vers le partage, puis recrée et démarre la trace au chemin initial. Les chemins locaux au serveur sont accédés via le partage administratif (`\\serveur\C$`); l'appelant doit avoir les droits requis. Les fichiers de destination déjà existants ne sont pas écrasés.

`Export-NamedTraceFile` utilise `Read-DbaTraceFile` et émet un `PSCustomObject` par événement. Le chemin doit être accessible au compte de service de l'instance SQL qui lit les traces. Cette commande n'écrit pas elle-même un fichier : redirigez les objets vers `Export-Csv`, `ConvertTo-Json` ou votre propre destination.

Les opérations qui modifient une trace prennent en charge `-WhatIf` et `-Confirm`.

> SQL Trace/Profiler est une fonctionnalité dépréciée par Microsoft. Ce module la cible pour les environnements qui en dépendent déjà; pour un nouveau système de collecte, privilégiez Extended Events.
