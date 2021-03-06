# 01 Juin 2017
    <script src='https://webrtc.github.io/adapter/adapter-latest.js'></script>

**Intro**:

Le système easybroadcast qui a la capacité de réduire le flux d’internet de Vidéo/Audio stream, entraînant une augmentation majeur de la performance.  

**Objectif**:

{0}. [x] Connaître le système easybroadcast (la structure générale en regardant les codes)


# 02 Juin

**Objectif**:

{0}. [x] Connaître le système easybroadcast. (apprendre les concepts HLS, WebRTC et la structure de class)

**Concepts Apris**:

> **HLS**: Http Live Stream, c’est un protocole basé sur le protocole HTTP. Ce protocole divise les ressources audiovisuel en des fichiers HTTP. Donc avec HLS, on peut utiliser CDN pour distribuer les ressources audiovisuel. Dans ce projet, VideoJS et JWPlayer (deux type de vidéo players) ont eux-même implémenté le protocole HLS.

> **WebRTC**: WebRTC est API qui permet d'échanger entre Peers en temps réel. Matrics: C’est sont les données qui sont intéressant à analyser sur le dashboard. Chaque peer au cours de regarder un video envoie les données dans le format Matrics au manager.

> **Room**: Le groupe de peers qui sont en train de regarder le même vidéo.Swarm: Les peers dans le même Room qui échange avec ce peer là.  


# 06 Juin

**Objectif**:

{0}. [x] Finir la graphe de communication entre peer.
{0}. [x] Apprendre le concept WebWorker: Comprendre la notion: leechers, peer liste et seeder. SwarmSize indique le largeur de quoi?
{0}. [x] Trouver au moins une solution pour la fonction getScore qui évalue la qualité de Peer.  

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

{0}. [x] Mesurer le faisailité de chaque solution.
{0}. [x] La conception d'un système du score.

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

# 08 Juin

**Objectif:**

{0}. [x] coder la solution et faire le test.

**Modification de la solution:**

On a proposé de changer le mésurement fiablité comme le pourcentage d'envoi d'une paquette, et ce valeur est mis à 1 initialement. Et puis, il m'a dit que RTT doivent être mésuré selon la requête Interest parce qu'on cherche les peers plus libres. Mais en fait, le degree de librement change toujours, et l'effet du reseaux est plus important que la calcul local. En fait, le peer qui a un bon etat de reseaux doit être responsable à echanger plus avec les autres.

L'autre proposition est qu'on peut calculer la fiablitlié selon réponse/requete

Résultat: La résultat est assez bien. Si je pause un peer, le score tombe progressivement pour ce peer.

**Suite:**

j'ai testé ce que j'ai fait pour la premiere version. J'ai trouvé que ça fait long temps pour détecter qu'un peer arrête le stream. Donc je pense qu'on peut ajouter un ***pénalité*** pour la reponse ***choke* ou *busy*.**

Pour finaliser la calcul d'un score. la possibilité d'envoi n'est pas très util. On doit adapter la calcul à chaque différent requête afin de milleur encourager les bonnes et punir les mauvais.

| Reçu     | Classe de peer | Explication                              |
| -------- | -------------- | ---------------------------------------- |
| Contain  | +++            | Ce qui m'envoie contain est ce qui a la paquette que je veux |
| Satisfy  | ++             | Ce qui m'envoie satisfy est ce qui me plaît le plus, du coup, c'est le peer plus intéressant. |
| Choke    | ---            | Ce qui choke.                            |
| Busy     | --             | Ce qui est occupé.                       |
| Interest | +              |                                          |
| Request  | +              |                                          |
| Ping     | °              |                                          |
| Pong     | °              |                                          |

En fin, je dois concevoire intégrer bande passante dans le système du score.

# 09 Juin

- [ ] Concevoir la façon d'intégration de la bande passante dans le système du score.
- [ ] Coder la bande passante et tester le score.
- [ ] Trouver la façon de faire le test dans un plus grand network.

Aujourd'hui, j'ai fait le research sur elasticsearch et du coup, j'ai trouvé que c'est un système qui permet d'implémenter la fonctionalité de research très facilement, sans effort. En plus, c'est le research elastic, CàD on peut également utiliser les shards pour dupliquer et distribuer les données dans plusieur serveur. Ça peut être utiliser dans le partie dashboard.

# 12 Juin

- [x] Trouver un moyen d'evaluer la performance d'échange entre peer.
- [x] Installer l'elasticsearch sur le serveur
- [x] Concevoir l'indice et type de document

**Resultât:**

Je propose d'utiliser l'elasticsearch pour l'analyse. Car l'elasticsearch permet l'envoie des statistiques facilement pour le front-end. Donc, je vais concevoir les indices et types pour stocker les stats qui sont utils à analyser la performance.

Des trucs à analyser sont comme desous.

| Nom                            | Description                              |
| ------------------------------ | ---------------------------------------- |
| Occupation CPU                 | ….                                       |
| Vitesse de transmission(Moyen) | J'envoie à le serveur elasticsearch kb et le temps. |
| Ratio d'occupation             | Calculer depuis le nom de leetcher de chaque peer. |
| Des metrics                    | Le metric pour chaque paquette.          |
|                                |                                          |

# 13 Juin

- [x] Réalisation d'indice et les mapping pour l'analyse.
- [x] Le plugin qui permet d'envoyer les statistiques à l'ES

**Resultât: **

Pour aujourd'hui, j'ai utilisé la plupart du temps pour réaliser et améliorer le structure du type `performance` dans ES, qui stocker des statistiques pour analyse. Pour le moment, le structure est comme ci-dessous:

```json
PUT performance
{
  "mappings": {
    "realtimestatus": {
      "_all": {
        "enabled": false
      },
      "properties": {
        "userhash": {"type": "text"},
        "date": {"type": "date"},
        "containCount": {"type": "integer"},
        "containTimespent": {"type": "integer"},
        "pingCount": {"type": "integer"},
        "pingTimespent": {"type": "integer"},
        "requestCount": {"type": "integer"},
        "requestTimespent": {"type": "integer"},
        "busyCount": {"type": "integer"},
        "busyTimespent": {"type": "integer"},
        "chokeCount": {"type": "integer"},
        "chokeTimespent": {"type": "integer"},
        "pongCount": {"type": "integer"},
        "pongTimespent": {"type": "integer"},
        "satisfyCount": {"type": "integer"},
        "satisfyTimespent": {"type": "integer"},
        "interestCount": {"type": "integer"},
        "interestTimespent": {"type": "integer"},
        "useScore": {"type": "boolean"}
      }
    }
  }
}
```

On peut désormais se bénefier du système kibana qui permet des analyse en temps réal et totalement personalisé. J'ai essayé d'ajouter des graphes, ça passe très bien. Le code ElasticPlugin.js est la réalisation du plugin.

# 14 Juin

- [x] Intégration du plugin.
- [x] Écrire Wiki de mon partie.
- [x] Installer X-pack qui permet de gérer les utilisateurs.

```markdown
# Elasticsearch

Elasticsearch is install on the machine `5.192.1.116`. The bin file is at `/usr/share/elasticsearch`. This is basically the engin to facilite the processus of analysing the performance of the newly added selection of peer, which is presented in article 'Selection of Peer'. This elasticsearch server can be futhur used to implement the dashbroad too.

## Version

5.4

## How To Start, stop and restart

`sudo -i service elasticsearch [start|stop|restart]`

## How To Configurate

`cd /etc/elasticsearch`

`vi elasticsearch.yml`

All the configuration options are presented in this file. The manual for configuration can be found on the website of Elasticsearch. <u>https://www.elastic.co</u>

## How to send data to elastic search with REST API from browser

>  In order to let all players send analytic data to this elasticsearch server, it's required to setup the CORS in elasticsearch.yml to allow CORS from different origins.

Remember to add a header `Authorisation: Basic <token>` to the request, where the `<token>` means base64 encoded string `username:password`, for example, in our system is `elastic:easyboardcast`, which after encode becomes `ZWxhc3RpYzplYXN5YnJvYWRjYXN0`.

Headers like this in each request is required:

​```jSon
headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Basic ZWxhc3RpYzplYXN5YnJvYWRjYXN0'
      }
​```

**!!Security Issue: this usage is not safe, because in client code, this header configuration is visible to all. Better create a proxy server to handle request and filter unauthorized origin**

My current solution for the security issue is to limit CORS request to use just POST method.

​```yaml
# this is in /etc/elasticsearch/elasticsearch.yml
http.cors.enabled: true
http.cors.allow-origin: "*"
http.cors.allow-headers: Content-Type, Authorization
http.cors.allow-methods: POST
​```



# Kibana

Kibana is the tool for creating visualization to the data retrieved from elasticsearch. This tool is very flexible and useful.

## How To Start, Stop and Restart

generaly the same as elasticsearch,

`sudo -i service kibana [start | stop | restart]`

## How To Configure

`cd /etc/kibana`

`vi kibana.yml`
```



# 15 Juin

- [x] Intégration du partie interest et request du plugin.
- [x] Améliorer et ajouter des données envoyé à l'elasticsearch.
- [ ] Écrire wiki du partie protocole.
- [x] Concevoir la visualisation qui permet de dire si la performance était améliorée ou pas.

```markdown
# Finding the best peer to communicate with
> Principle: since the score of peer is mesured within each communication, we should find a way to do so.
> I calculate the score with the function evaluatePeers which can be found in v2vManager.js. The function relate the score with the rtt between the peer and the type of commucation we have with the peer. Each contain response, we'll give the peer 2 points. Each finished satisfy, we'll give the peer 2 points. Cuz, in this case, those new peers who have the newest content available will send back 'contain', and win points and have more chance to exchange with other peers. For those who choke or who is busy will get no points event lose points.

In the following chapter, I'll discuss about the way that I implement it.

## Peer.js
In peer.js, I've added lines of code that count each type of request-response as stated above. These parts are noted with a comment `// Written by Olivier`. You shall find it immediately.

## V2VManger.js
### Initialization:
In this file, I've added in the constructor severals lines of code: initialize _useScore (whether to use my function of calculate Score), initialize _sendingStatsToES (whether to send the statistics to elasticsearch), initialize ElasticRequester which implements the functionalities of sending statistics to the elasticsearch server. These configurations are set in eb.js after initialization of V2Vmanager.
### Score calculation:
The function named evaluatePeers () is called each time when one peer response pong. In this case, the score of peers is relatively changed when some peers in the swarm response pong to the peer. The result of the score is then used to select the best peer to request the video package.
## eb.js
To enable userScoring and sendingStatsToES
## Elastic Plugin
```

**Résultat:**
1. Aujourd'hui, j'ai pu réaliser l'envoie des évenements de l'interest et request. Donc pour l'instant, chaque évenement contient les données `timestamp`, `eventtype`, `payload`, `userhash`, `timespent`. Ça c'est suffissant pour calculer la vitesse moyenne et les pourcentage pour chaque évenement. On peut désoremais analyser la performance à partir de ça.

2. J'ai crée trois types de visualisation pour bien voir les différences causées par ce plugin. La première à noter, c'est la diagrame de vitesse moyenne divisée par `useScoring` qui indique si ce peer utilise la fonction que j'ai créée ou pas. C'est un peu difficile pour le début, parce que le requête pour calculer ça est dans une forme que je ne connais pas. Pourtant, j'ai trouvé des tutorial sur internet qui me permet de faire ça. Ensuite, la deuxième diagram, qui affiche les pourcentage de satisfy, interest-contain, interest-choke, interest-busy, ping. Le résultât de la comparasion est que il n'y a pas de différence remarquable entre les deux cas. Mais des idées m'arrivent qu'on doit aussi ***mesurer les échecs lors de satisfy***.  

# 19 Juin
Le tâche principal d'aujourd'hui, c'est d'intégrer mon partie dans un l'environement de production pour qu'on puisse determiner si la performance serait améliorée ou pas. C'est une démarche importante dans mon sujet. Demain, on peut indentifier les différences causées par ma fonction de donner des notes aux peers. Finalement, j'ai ajouté quelque graphe permettant d'afficher plus clairement les statistics de ces deux type. L'une est un histograme de nombre de peer et le volumn téléchargé par v2v comparé par raport à `usescoring`. En plus, j'envoie aussi `location.origin` et `location.href` pour qu'on identifie l'origin de stats envoyés.



# 20 Juin

- [x] Comparer le résultat du test.
- [ ] Analyse à partir de graphe de comparaison.  
- [ ] Trouver quelque solution qui puisse améliorer la fonction de scoring.



## Analyse réalisée

1. Vitesse moyenne: dans cet aspect, la vitesse de peer qui n'utilise pas le scoring est superieur que celui qui l'utilise.
2. Tout les deux ont autant de close-peer, c'est à dire, tout les peers ne sont pas stable.
3. Il y a 2 GB de données transferts dans le test.
4. Les peers qui n'utilisent pas le scoring transferent 60 pourcents plus de données qui ceux qui l'utilisent.
5. Il y a deux heures où les peers qui utilisent le scoring sont légèrement mieux que ceux qui ne l'utilisent pas. Et Mais les 4 heures suivants, le cas est l'inverse.

### pourquoi ?
1. une raison peut être que la calculation de score prenne trop de CPU, et du coup il tardit la réponse à l'autres peers.  

## Amélioration envisagée
1. Améliorer l'algorithme afin qu'il ne prenne pas beaucoup de CPU --- L'on peut reduire l'action de calculer, car pour l'instant, on calcule les scores en recevant chaque ping. Donc pour une évaluation totale, il fallait calculer 10 fois.
2. Éliminer les peers qui soivent mauvais et remplacer-les avec des nouveaux arrivés.

# 21 Juin
- [x] Trouver le problème qu'on a rencontré hier soir que les peers qui utilisent la fonction ne peut pas charger de partie
- [x] Améliorer la visualisation de statistics afin qu'on peut voir les flux d'utilisateur au cours du temps.
- [x] Améliorer la manière qu'on télécharge les statistiques à l'ES.

**Résultat**
Le problème qu'ils ont rencontrés, c'est qu'ils ne demandent pas à les autres peers dont les scores sont moins zéro. C'est le point que je n'avait pas connu quand je changais la fonction comme -rtt. Du coup, je rajoute 40000 pour tous les peers afin qu'ils peuvent être plus de zéro.
J'ai ajouté deux graphes. L'une est les pourcentages de système d'opération et le type et la version du browser.
Afin qu'on peut reduire l'occupation du réseaux quand on serait en train de voir un vidéo.
# 23 Juin
- [x] Trouver la cause quand on ferme un peer.
- [x] Améliorer la sélection d'un peer.
- [x] Activer la fonction de sélection totalement.
- [x] Implémentation d'une version où les peers envoient plusieurs requests. Ce nombre peut être confuguré dans Option.
**Résultat**
1. Si le channel de RTC entre peer était coupé, le client serait fermé et du coup ils envoyent close à l'elasticsearch. It is beyond our control.  
2. Une question à répondre, c'est quoi qui différentie deux peer. C'est RTT ou d'autres choses. Oui pour l'instant car c'est plus simple et consistent à utiliser. Mais surtout, la performance en gros n'a pas été amélioré définitivement. Donc, il faut trouver le le goulot systématique.
3. J'ai ajouté un nouvel indicateur qui s'appele 'redundant-satisfy'. C'est à dire c'est un satisfy inutil. J'espère qu'on peut acquérir meilleur vitesse en envoyant les requests redundants.

**Sujet Nouvel**
J'ai reçu deux sujets suivants. L'un est d'intégrer 'hava' dans l'échange. Ce message communique que j'ai quelque paquette et tu peux me chercher si tu as besoin.
# 26 Juin
- [ ] ajouter plus d'information dans interest. Il faut contenir les paquettes que j'ai et que je veux.
- [x] refléchir comment faire un manager simple de nouveaux protocole.
- [x] établir la structure du serveur websocket.

**Résultât**
1. Il paraît que je dois aussi faire le serveur du protocol qui sera codé en Python. Du coup, je dois apprendre un peu Python 3 où il y a pas mal de détails que je ne connais jamais. Par exemple, les mots clés: await, yield etc.
2. J'ai crée la structure du serveur qui initilise websocket et entre dans un boucle d'evenement afin de pouvoir distribuer les messages et les traiter

# 27 Juin
- [ ] Installer le système de distribution du message.
- [ ] Configurer les messages et les traitements.
- [ ] Trouver la façon qu'on stocker les peers dans mémoire.
- [ ] Apprendre comment s'établir la connection entre deux peer.

# 28 Juin
- [x] Comprendre JSEP.
- [ ] Conception d'un systeme de p2p signaling pour easybroadcast v2.0.


# 29 Juin
- [ ] Conception d'un signaller pour le front-end

# 10 Juillet

## Objectif
1. Enreigistrer l'entree du peer et sortie du peer enfin de prevenir à l'elasticsearch.
2. Trouver la facon d'integrer la geogalisation.

## Résultat
1. On peut envoyer des stats dans WebSocketHandler.
2. Il y a deux étaps pour établir le long et le latitude du peer. **obtenir ip addresse** et puis **geoip transformation**. Pour chaque peer qui entre, le s-server effectue une k-nn recherche, et retour k peer qui sont les plus proches peer. L'algorithme pour selectionner un peer, je vais étudier une thèse Fast k-NN Seearch. Le travail suivant peut être l'intégration la geolocalisation dans le projet et implémenter ou introduire l'algorithme k-nn recherche dans le projet.

## Suite
1. Ajouter plus d'information dans le message interest, contain etc pour indiquer les infos sur timeshift afin qu'on peut request directement à des peers. Du coup, il va reduire les rêquetes qui sont pas trop utils.

# 11 Juillet
**Tâches faites:**
1. Faire le teste sur le lib GeoIP de python. J'ai trouvé que le base de donnée de format .csv et .dat ne marche pas avec GeoIP2 python API. Du coup, j'ai téléchargé les libs gratuits pour ça. le base de données s'appele GeoLite2-City et GetLite2-Country.
2. Integrer dans le server.
3. Quand un peer entre, le server indique a l'elasticsearch pour enregistrement.

**Tâche suivante:**
1. Améliorer l'échange entre peer comme: porter l'information de timeshift dans le rêquete interest.

# 12 Juillet
**Tâches faites**
1. Ajouter le méchanism de reconnect pour assurer l'échange entre peer, et ajouté une fonction qui permet de relacher tous les resources utilisé, et supprimer les listeners qui pouvait causer memory leak.
2. Le machanism de reconnecter est: s'il est déconnecte du s-server et il n'a plus assez d'echange avec autres peers. Il va faire le reconnect total, c'est à dire, fermez tous les connexions de peer, et réinitialize tout.

# 17 Juillet
**Things to Do**:
- [x] Add a traffic monitor for elasticsearch so as to be see how much traffic are required for certain number of user.
- [x] Correct a bug that happens when closes a peer not properly and result in memory leak.
- [ ] Write Wiki for part p2p.

**Result**:
1. I tried to use packetbeats to wrap up network information, and tried another packet catch tools but they are too useful to just implement such a simple functionality. So I use just `len(message)` to calculate the length of message so as to see how much bandwidth is been used by the users.
2. I've found a bug that: Resource is not defined in the function matching the timeshift and corrected it.

# 21 Juillet
- [x] The driver of Dashjs

# 24 Juillet
**Things to do**:
- [x] Add the seperated way of loading eb.js
- [x] Clean the code of Dashjs


# 25 Juillet
**Things to do**:
- [ ] Think about the change of resoluion issue.
- [ ] Think about timeshift issue.


# BUG LIST
1. Dashjs will block automaticly and keep requesting mpd.
2. Metrics raised a error on the function Utilities.round(), when moving the timeshift control, the bufferLength becomes NaN. 

#26 - 30 Juillet
1. Delopy the new version in espacetv, ghanalive/atom and nessma for testing, where there is thousands of users per day. 
2. Found the memory leak in the code and corrected them.
3. Understand more about the EbLibrary's sending content. The content should be sent in format of sliced ArrayBuffer. Each video/audio content is sliced into 7-10 parts.


# Rapport Stage:
## 1. Présentation l'entreprise (entreprise > service > equipe lie a stage)
Easybroadcast est une entreprise qui propose une solution hybride associant le modèle classique Client/Serveur (lorsque le traffic est faible) et le modèle décentralisé (pair à pair) quand le trafic s’intensifie, afin de pouvoir réduire l'utilisation et dépendence de CDN. Ça peut réduire la bande passante pour diffuser les contenus vidéo et audio énormément. Le système mets en rélation les viewers dans un même video pour qu'il peuvent se partager les contenues vidéo et audio. Plus les audiances sont, meilleur la performance du système sera. Il peut réduire la consommation de bande passant jusqu'à 75 pourcent. Hybride il s'agit de commuter entre CDN et P2P automatiqument selon la condition de réseau et les peers. Les calcus de timing de la choix de mode sont fait pour que la transition entre P2P et CDN soit harmonieuse. Le système permet de transformer un large audience en atout. 
## 2. gestion de projet
## 3. cahier des charges
## 4. Travail realise (Mission, que faites-vous, pourquoi l'entrepris vous a-t-elle fait venir, résultat, )
## 5. Conclusion
