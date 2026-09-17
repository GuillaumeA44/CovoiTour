# Bilan de simulation d’équité

## Contexte

- Période simulée : octobre et novembre 2026, 43 jours ouvrés.
- Groupe : 4 personnes, chacune possède un véhicule de 4 places passager.
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
| Temps Plein A | Temps plein, vacances pendant tout le mois de novembre, véhicule 4 places passager |
| Temps Plein B | Temps plein sur toute la période, véhicule 4 places passager |
| Trois Jours Sur Cinq | Présence lundi, mercredi et vendredi, véhicule 4 places passager |
| Arrivee Milieu | Présence uniquement du 12 au 23 octobre, soit 2 semaines, véhicule 4 places passager |

## Résultats globaux

- Jours avec au moins deux participants et entièrement couverts : 35/43.
- Jours avec une seule personne présente, donc sans covoiturage possible : 8.
- Personnes non affectées : 0.
- Écart maximal du coefficient conduites / présences : 0.08.

## Tableau récapitulatif individuel

| Personne | Présences | Jours conduits | Jours conduits / jours présents (coût réel) | Capacité véhicule | Passagers transportés | Charge normalisée par conduite | Score final |
|---|---:|---:|---:|---:|---:|---:|---:|
| Temps Plein A | 22 | 8 | 8 / 22 = 0.36 | 4 | 13 | 0.41 | -0.16 |
| Temps Plein B | 43 | 14 | 14 / 43 = 0.33 | 4 | 21 | 0.38 | 0.67 |
| Trois Jours Sur Cinq | 26 | 10 | 10 / 26 = 0.38 | 4 | 16 | 0.40 | 0.06 |
| Arrivee Milieu | 10 | 3 | 3 / 10 = 0.30 | 4 | 8 | 0.67 | -0.83 |

## Lecture du bilan

- Le coût réel individuel est affiché sous la forme `jours conduits / jours présents`.
- La charge normalisée par conduite est `passagers transportés / (capacité × jours conduits)`.
- Formule complète : `Score final = Score d’équité + (0,1 × Score de contribution) − Bonus de priorité`.
- Les vacances, absences et jours sans présence ne sont pas comptés dans le dénominateur.
