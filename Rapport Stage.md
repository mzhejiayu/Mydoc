# 01 Juin 2017

**Intro**: 

Le système easybroadcast qui a la capacité de réduire le flux d’internet de Vidéo/Audio stream, entraînant une augmentation majeur de la performance.  

**Objectif**: 

1. Connaître le système easybroadcast (la structure générale en regardant les codes) 

# 02 Juin

**Objectif**: 

1. Connaître le système easybroadcast. (apprendre les concepts HLS, WebRTC et la structure de class)

**Concepts Apris**: 

> **HLS**: Http Live Stream, c’est un protocole basé sur le protocole HTTP. Ce protocole divise les ressources audiovisuel en des fichiers HTTP. Donc avec HLS, on peut utiliser CDN pour distribuer les ressources audiovisuel. Dans ce projet, VideoJS et JWPlayer (deux type de vidéo players) ont eux-même implémenté le protocole HLS. 

> **WebRTC**: WebRTC est API qui permet d'échanger entre Peers en temps réel. Matrics: C’est sont les données qui sont intéressant à analyser sur le dashboard. Chaque peer au cours de regarder un video envoie les données dans le format Matrics au manager.

> **Room**: Le groupe de peers qui sont en train de regarder le même vidéo.Swarm: Les peers dans le même Room qui échange avec ce peer là.  

# 06 Juin

**Objectif**: 

1. Finir la graphe de communication entre peer. 
2. Apprendre le concept WebWorker: Comprendre la notion: leechers, peer liste et seeder. SwarmSize indique le largeur de quoi?
3. Trouver au moins une solution pour la fonction getScore qui évalue la qualité de Peer.  

**Résultat**:

> **SwarmSize** est le largeur de tous les peers que je retiens dans le mémoire et avec qui j’échange des chunks. Dans le swarm, il y a deux type de peer. L'un est les candidates pour certain chunk, autant dire que ces candidates ont le chunk auquel je suis intéressé, l'autre est les ejects qui sont l'inverse de candidate. 
>
> **Leetchers** sont des peers à qui j'envoie des chunks. **Seeder** est l'inverse. 

> Dans le code, on peut voir qu'on démande justement à un seul peer qui est evalué comme le meilleur peer selon le score. Voici le partie que je doit se brouiller. Ce score est mis en 1000 pour tous les peers pour l'instant. Donc je propose de calculer le score selon RTT(Round-Trip time) qui peut mesurer bien le temps à parcourir entre deux peer. 

La solution du score de chaque peer, il en y a deux. 

1. utiliser le RTT pour la requête sendInterest
2. calculer le score selon la bande passante (le largeur de contenu reçu / temps parcouru)

# 07 Juin

**Objectif:**

1. Mesurer le faisailité de chaque solution. 
2. La conception d'un système du score. 

**Résultat**:

Voilà trois types des statistiques qu'on peut s'en servir pour mesure le score: 

1. la fréquence de la discussion. C'est à dire, si un peer est habituel à discuter avec moi, c'est plus stable et plus fiable. 
2. la bande passante calculé selon la formule $largeurDeContenu/temps$. C'est le mesurement plus pratique, car on doit acquiere les données de la façon rapide. 
3. la fréquence de la déconnexion de certain peut servir comme un pénalité du score, car elle indique l'instablité d'une connextion entre peer. 
4. RTT des requêtes sans CONTENU, c'est un mesurement rapide et facile. 

Donc, pour le moment, il faut choisir les méthodes à implementer et les donner un poids pour les combiner.

**Pour la suite, on peut également mésurer de coté du manageur qui a une trace de chaque peer.**

|                       nom | faisabilité | explication                              |
| ------------------------: | :---------: | :--------------------------------------- |
|   Fréquence de discussion |     OUI     | calculer le pourcentage $discussionAvecUnPeer/discussionAvecTous$ |
|            Bande passante |     OUI     | ajouter un parametre dans la requête sendSatisfy `sentTime` qui indique le datetime de cet envoie. calculer le temps parcouru dans la fonction `_onSatisfy`. calculer la bande passante selon la formule. Il faut modifier le classe EBMessage pour ajouter un timestamp pour chaque message. |
| Fréquence de Déconnextion |     OUI     | ça peut être un pourcentage qui est celui du nombre de requête envoyé avant un déconnexion. Par exmple, j'ai envoyé 5 requêtes et j'ai reçu une déconnexion, du coup, ce pourcentage est 1/5 = 0.2. Le fiablité du peer est 1-0.2 = 0.8 |
|          RTT sans CONTENU |    *OUI     | on peut justement mésurer ping et pong qui sont envoyés immédiatement. Par contre, les autres requêtes peuvent entraîner les temps d'attente d'envoie des autres messages dans le liste qui pourrait pas être un indicator pour mésurer un peer. |

Voici le formule pour calculer le score. 

$ScoreGeneral = \frac{\sqrt{PossibilitéEnvoie}\times Fiabilité}{\log(RTT)}$

$BandePassante=\frac{ContenuEnvoie}{Temps}$ 

le premier formule est pour la premiere évaluation. 

le deuxième est pour l'évaluation suivante si neccessaire. 

```javascript
// This code is used to calculate sqrt(possibilty of sending message)
var peerList = [4,6,8,3,1,1,100,1,1]

var sum:number = peerList.reduce((a:number,b:number) => {
  return a+b
})

console.log(peerList.map((each:number) => {
  return Math.sqrt(each/sum)
}))

```

$Fiabilité = 1-\frac{1}{N_{succss}}$

En fait, une évaluation de la fiabilité n'est pas assez correcte car un échec peut être un cas aléatoire. Donc on peut remettre la fiabilité à 1 pour certain peer aléatoirement 30 secondes. 