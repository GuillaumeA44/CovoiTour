# CovoiTour

> Le covoiturage equitable ou chacun conduit a son tour.

Application Flutter Android-first pour organiser un covoiturage regulier entre les memes personnes. Le code reste multiplateforme afin de permettre une version iPhone plus tard.

## Etat du projet

La base du projet contient :

- architecture `core`, `domain`, `data`, `presentation` ;
- modele de groupe, membres, presence et trajet aller-retour ;
- calcul d'equite avec somme des points egale a zero ;
- suggestion du conducteur avec regle de recence ;
- premier ecran Material 3 ;
- tests unitaires du calcul des scores ;
- scripts Windows de compilation release et d'installation ADB.
- planification multi-vehicules et repartition des passagers ;
- statistiques conducteur/passager ;
- contrats de rappels locaux et de geolocalisation temporaire ;
- export JSON versionne et detection de conflit de revision.

La synchronisation Google Drive, les notifications natives et la geolocalisation temps reel sont representees par des abstractions afin de ne pas coupler l'algorithme metier aux secrets ou APIs d'une plateforme. Le branchement concret necessitera la configuration OAuth Google Cloud, les permissions Android et un service de partage de position.

## Environnement

Installer sur le poste de developpement :

1. Flutter stable (incluant Dart).
2. Android Studio avec Android SDK, platform-tools et un JDK compatible.
3. Android SDK Platform correspondant au `compileSdk` genere par Flutter.
4. Git.

Puis verifier :

```powershell
flutter doctor
flutter pub get
flutter test
flutter run
```

Le projet Android natif (`android/`) est genere par `flutter create .` depuis la racine, sur un poste disposant de Flutter :

```powershell
flutter create --platforms=android .
flutter pub get
```

Pour conserver le package utilise par `TransfertRelease.bat`, utiliser plutot :

```powershell
flutter create --org com.covoitour --project-name covoi_tour --platforms=android .
```

Ne pas commiter `android/local.properties`, les keystores ni les secrets OAuth.

## Compilation Android

Pour un APK de test ou d'installation directe :

```text
CompilationRelease.bat
```

Pour installer l'APK release sur un appareil connecte et autorise en USB :

```text
TransfertRelease.bat
```

Pour supprimer les donnees locales avant installation :

```text
TransfertRelease.bat --clean
```

Pour publier sur Google Play, utiliser de preference :

```powershell
flutter build appbundle --release
```

## Google Drive

La version cible utilise un fichier JSON partage dans le Google Drive de l'administrateur. Le branchement necessitera :

- un projet Google Cloud ;
- OAuth Android avec le nom de package final et l'empreinte SHA-1 ;
- les scopes Drive strictement necessaires ;
- une strategie de version/revision avant chaque ecriture ;
- une sauvegarde avant modification importante.

Aucun secret Google ne doit etre committe dans Git.