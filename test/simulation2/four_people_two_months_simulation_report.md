# Bilan de simulation d’équité

## Contexte

- Période simulée : octobre et novembre 2026, 43 jours ouvrés.
- Groupe : 4 personnes, chacune possède un véhicule de 3 places passager.
- Hypothèse métier : chaque personne présente et éligible doit conduire au moins une fois sur la période.
- Personnes ayant effectivement conduit : 4/4.
- Seuil de conduite minimale : 10 présences sans conduire.
- Le coefficient individuel est calculé ainsi : `jours conduits / jours présents`.
- La charge normalisée par conduite est calculée ainsi : `passagers transportés / (capacité × jours conduits)`.
- Le score final est calculé ainsi : `score d’équité + (0,1 × score de contribution) − bonus de priorité`.
- Le score d’équité compare directement le ratio de conduite individuel au ratio moyen du groupe.

### Profils et contraintes

| Personne | Profil |
|---|---|
| Alpha Temps Plein | Présence 100 %, véhicule 3 places passager |
| Beta Temps Plein | Présence 100 %, véhicule 3 places passager |
| Gamma Mardi Absent | Absent chaque mardi, véhicule 3 places passager |
| Delta Jeudi Absent | Absent chaque jeudi et début novembre, véhicule 3 places passager |

## Résultats globaux

- Jours entièrement couverts : 43/43.
- Personnes non affectées : 0.
- Écart maximal du coefficient conduites / présences : 0.01.

## Tableau récapitulatif individuel

| Personne | Présences | Jours conduits | Jours conduits / jours présents (coût réel) | Capacité véhicule | Passagers transportés | Charge normalisée par conduite | Score final |
|---|---:|---:|---:|---:|---:|---:|---:|
| Alpha Temps Plein | 43 | 12 | 12 / 43 = 0.28 | 3 | 29 | 0.81 | -0.13 |
| Beta Temps Plein | 43 | 12 | 12 / 43 = 0.28 | 3 | 30 | 0.83 | 0.07 |
| Gamma Mardi Absent | 35 | 10 | 10 / 35 = 0.29 | 3 | 27 | 0.90 | -0.12 |
| Delta Jeudi Absent | 31 | 9 | 9 / 31 = 0.29 | 3 | 23 | 0.85 | -0.42 |

## Lecture du bilan

- Le coût réel individuel est affiché sous la forme `jours conduits / jours présents`.
- La charge normalisée par conduite est `passagers transportés / (capacité × jours conduits)`.
- Formule complète : `Score final = Score d’équité + (0,1 × Score de contribution) − Bonus de priorité`.
- Les absences et les jours sans présence ne sont pas comptés dans le dénominateur.
