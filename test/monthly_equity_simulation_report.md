# Bilan de simulation d’équité

## Contexte

- Période simulée : septembre 2026, 22 jours ouvrés.
- Groupe : 9 personnes, chacune possède un véhicule ; le moteur sélectionne le nombre minimal de véhicules nécessaires.
- Hypothèse métier : chaque personne présente et éligible doit conduire au moins une fois sur la période.
- Personnes ayant effectivement conduit : 9/9.
- Seuil de conduite minimale : 10 présences sans conduire.
- Le nombre de voitures est minimisé avant de comparer la somme des scores finaux.
- Le coefficient individuel est calculé ainsi : `jours conduits / jours présents`.
- La charge normalisée par conduite est calculée ainsi : `passagers transportés / (capacité × jours conduits)`.
- Le score final est calculé ainsi : `score d’équité + (0,1 × score de contribution) − bonus de priorité`.
- Le score d’équité compare directement le ratio de conduite individuel au ratio moyen du groupe.
- Le score de contribution compare les passagers transportés à la contribution moyenne du groupe.
- Le bonus de priorité vaut `présences depuis la dernière conduite / 10`.

### Profils et contraintes

| Personne | Profil |
|---|---|
| Grande Voiture | Présence 100 %, véhicule 5 places passager |
| Petite Voiture | Présence 100 %, véhicule 3 places passager |
| Temps Plein A | Présence 100 %, véhicule 3 places passager |
| Temps Plein B | Présence 100 %, véhicule 3 places passager |
| Mi Temps | Présence 50 %, véhicule 3 places passager |
| Quart Temps | Présence 25 %, véhicule 3 places passager |
| Tele Travail | Présence 100 %, télétravail chaque mercredi, véhicule 3 places passager |
| Vacances Ete | Présence 100 %, vacances du 8 au 12 septembre, véhicule 3 places passager |
| Nouveau Membre | Nouveau membre dès le 10 septembre, véhicule 3 places passager |

## Résultats globaux

- Jours entièrement couverts : 22/22.
- Personnes non affectées : 0.
- Écart maximal sans conduire pour les conducteurs : 6 jours.
- Écart maximal de charge normalisée par conduite : 0.33.
- Écart maximal du coefficient conduites / présences : 0.05.
- Exception testée : le 15 septembre, la petite voiture est indisponible.

## Tableau récapitulatif individuel

| Personne | Présences | Jours conduits | Jours conduits / jours présents (coût réel) | Capacité véhicule | Passagers transportés | Charge normalisée par conduite | Score final |
|---|---:|---:|---:|---:|---:|---:|---:|
| Grande Voiture | 22 | 6 | 6 / 22 = 0.27 | 5 | 25 | 0.83 | 1.29 |
| Petite Voiture | 22 | 5 | 5 / 22 = 0.23 | 3 | 14 | 0.93 | -0.25 |
| Temps Plein A | 22 | 5 | 5 / 22 = 0.23 | 3 | 13 | 0.87 | -0.45 |
| Temps Plein B | 22 | 6 | 6 / 22 = 0.27 | 3 | 15 | 0.83 | 0.09 |
| Mi Temps | 11 | 3 | 3 / 11 = 0.27 | 3 | 9 | 1.00 | -0.31 |
| Quart Temps | 4 | 1 | 1 / 4 = 0.25 | 3 | 3 | 1.00 | -0.93 |
| Tele Travail | 17 | 4 | 4 / 17 = 0.24 | 3 | 8 | 0.67 | -0.85 |
| Vacances Ete | 18 | 4 | 4 / 18 = 0.22 | 3 | 12 | 1.00 | -0.36 |
| Nouveau Membre | 15 | 4 | 4 / 15 = 0.27 | 3 | 12 | 1.00 | -0.12 |

## Lecture du bilan

- Le coût réel individuel est affiché explicitement sous la forme `jours conduits / jours présents` : proche de `1`, la personne conduit presque à chaque présence ; proche de `0`, elle conduit peu ou pas encore.
- La charge normalisée par conduite est `passagers transportés / (capacité × jours conduits)`. Elle mesure le remplissage moyen de chaque trajet et permet de comparer une voiture de 5 places avec une voiture de 3 places.
- Formule complète : `Score final = Score d’équité + (0,1 × Score de contribution) − Bonus de priorité`.
- Exemple Grande Voiture : `0,13 + 2,42 − 0 = 2,55`.
- Un score final négatif est prioritaire sur un score positif. Le bonus et un faible nombre de conduites font donc baisser le score.
- Conclusion de cette simulation : l’écart est réduit, mais reste supérieur à 0,15 ; la répartition n’est donc pas encore parfaitement équitable.
- Les absences, vacances et télétravail ne sont pas comptés comme des présences.
