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