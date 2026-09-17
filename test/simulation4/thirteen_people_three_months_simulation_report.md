# Bilan de simulation d’équité

## Contexte

- Période simulée : octobre à décembre 2026, 66 jours ouvrés.
- Groupe : 13 personnes, chacune possède un véhicule de 4 places passager.
- Le nombre de voitures est déterminé par le nombre de personnes présentes et la capacité des véhicules.
- Hypothèse métier : chaque personne présente et éligible doit conduire au moins une fois sur la période.
- Personnes ayant effectivement conduit : 13/13.
- Le coefficient individuel est calculé ainsi : `jours conduits / jours présents`.
- La charge normalisée par conduite est calculée ainsi : `passagers transportés / (capacité × jours conduits)`.
- Le score final est calculé ainsi : `score d’équité + (0,1 × score de contribution) − bonus de priorité`.
- Le score d’équité compare directement le ratio de conduite individuel au ratio moyen du groupe.

### Profils et contraintes

| Personne | Profil |
|---|---|
| Temps Plein A | Temps plein, véhicule 4 places passager |
| Temps Plein B | Temps plein, véhicule 4 places passager |
| Temps Plein C | Temps plein, véhicule 4 places passager |
| Temps Plein D | Temps plein, véhicule 4 places passager |
| Vacances Novembre | Vacances pendant tout le mois de novembre, véhicule 4 places passager |
| Quatre Jours A | Présence 4 jours sur 5, véhicule 4 places passager |
| Quatre Jours B | Présence 4 jours sur 5, véhicule 4 places passager |
| Mi Temps A | Présence lundi, mercredi et vendredi, véhicule 4 places passager |
| Mi Temps B | Présence lundi, mercredi et vendredi, véhicule 4 places passager |
| Teletravail A | Télétravail chaque mercredi, véhicule 4 places passager |
| Teletravail B | Télétravail chaque mercredi, véhicule 4 places passager |
| Nouveau Membre | Arrivée le 16 novembre, véhicule 4 places passager |
| Arrivee Decembre | Arrivée le 1er décembre, véhicule 4 places passager |

## Résultats globaux

- Jours avec au moins deux participants et entièrement couverts : 66/66.
- Jours avec une seule personne présente : 0.
- Personnes non affectées : 0.
- Nombre maximal de voitures utilisées simultanément dans ce scénario : 3.
- Écart maximal du coefficient conduites / présences : 0.02.

## Tableau récapitulatif individuel

| Personne | Présences | Jours conduits | Jours conduits / jours présents (coût réel) | Capacité véhicule | Passagers transportés | Charge normalisée par conduite | Score final |
|---|---:|---:|---:|---:|---:|---:|---:|
| Temps Plein A | 66 | 14 | 14 / 66 = 0.21 | 4 | 50 | 0.89 | 1.20 |
| Temps Plein B | 66 | 14 | 14 / 66 = 0.21 | 4 | 46 | 0.82 | 0.70 |
| Temps Plein C | 66 | 14 | 14 / 66 = 0.21 | 4 | 49 | 0.88 | 1.00 |
| Temps Plein D | 66 | 13 | 13 / 66 = 0.20 | 4 | 43 | 0.83 | 0.19 |
| Vacances Novembre | 45 | 9 | 9 / 45 = 0.20 | 4 | 36 | 1.00 | -0.61 |
| Quatre Jours A | 53 | 11 | 11 / 53 = 0.21 | 4 | 42 | 0.95 | 0.10 |
| Quatre Jours B | 53 | 11 | 11 / 53 = 0.21 | 4 | 42 | 0.95 | 0.20 |
| Mi Temps A | 39 | 8 | 8 / 39 = 0.21 | 4 | 30 | 0.94 | -1.00 |
| Mi Temps B | 39 | 8 | 8 / 39 = 0.21 | 4 | 29 | 0.91 | -1.20 |
| Teletravail A | 53 | 11 | 11 / 53 = 0.21 | 4 | 40 | 0.91 | 0.00 |
| Teletravail B | 53 | 11 | 11 / 53 = 0.21 | 4 | 39 | 0.89 | -0.30 |
| Nouveau Membre | 34 | 7 | 7 / 34 = 0.21 | 4 | 28 | 1.00 | -1.20 |
| Arrivee Decembre | 23 | 5 | 5 / 23 = 0.22 | 4 | 20 | 1.00 | -1.79 |

## Lecture du bilan

- Le coût réel individuel est affiché sous la forme `jours conduits / jours présents`.
- La charge normalisée par conduite est `passagers transportés / (capacité × jours conduits)`.
- Formule complète : `Score final = Score d’équité + (0,1 × Score de contribution) − Bonus de priorité`.
- Les vacances, absences, télétravail et jours sans présence ne sont pas comptés dans le dénominateur.
