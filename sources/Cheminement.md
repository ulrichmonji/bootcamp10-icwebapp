
##Prérequis

- Avoir **Virtualbox** et **Vagrant** sur son poste de travail afin de provisionner le lab en local

## Etapes à suivre
### Build, test et push de l'image Docker
- Creation d'un répertoire de travail
- Téléchargement du vagrantfile et ses dépendances dans le répertoire de travail
- Ouvrir un terminal dans ce répertoire de travail et déployer Minikube dans virtualbox
- Une fois minikube OK, télécharger les sources dans la VM minikube (cette VM contient déja docker installé)
- Lancer le build de l'image et tester le fonctionnemet du conteneur :
> docker build --no-cache -t ic-webapp:v1.0 .
>docker run -d --name test-ic-webapp -p 8000:8080 ic-webapp:v1.0
- RDV dans le navigateur de votre machine, taper http://**<votre_ip_machine>**:**8000** pour finaliser le test
- Supprimer le conteneur une fois le test validé et pousser l'image dans dockerhub
> docker rm -f test-ic-webapp
> docker tag ic-webapp:v1.0 **<votre_id_docker_hub>**/ic-webapp:v1.0
> docker login
> docker push choco1992/ic-webapp:v1.0

### Automatisation via docker-compose (Bonus)
- On créé les répertoires devant servir de volumes et on set les droits. Pour des besoins de faciliter, on va attribuer tous les droits sur ces foldes
> sudo mkdir -p /data_docker/lib-odoo /data_docker/pgadmin4 /data_docker/postgres /data_docker/addons /data_docker/config
> sudo chmod 777 -R  /data_docker/lib-odoo /data_docker/pgadmin4 /data_docker/postgres /data_docker/addons /data_docker/config 
- Installation docker-compose
> sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
> sudo chmod +x /usr/local/bin/docker-compose

#### Infos
le docker-compose contient les variables ODOO_URL et  PGADMIN_URL qui doivent etre renseignées avec l'ip machine de la VM vagrant.
ce sont les lignes suivantes : 
>            - "ODOO_URL=http://${HOST_IP}:8069/"
>            - "PGADMIN_URL=http://${HOST_IP}:5050/"
Du coup la variable d'en HOST_IP doit contenir cette IP machine. Sur notre infra, on va travailler avec l'interface **enp0s8**. Du coup la commande suivante permets de facilement récupérer cette IP machine : 
> ip -4  a show enp0s8 | grep inet | awk '{print $2}' | awk -F'/' '{print $1}

- lancement la stack
> cd docker-ressources
> HOST_IP=$(ip -4  a show enp0s8 | grep inet | awk '{print $2}' | awk -F'/' '{print $1}')   docker-compose up -d
- RDV dans le navigateur de votre machine, taper http://**<votre_ip_machine>**:**8080** pour finaliser le test


### Déploiement sur K8S
- On créé les répertoires devant servir de volumes et on set les droits. Pour des besoins de faciliter, on va attribuer tous les droits sur ces foldes
> sudo mkdir -p /data_k8s/lib-odoo /data_k8s/pgadmin4 /data_k8s/postgres /data_k8s/addons /data_k8s/config
> sudo chmod 777 -R  /data_k8s/lib-odoo /data_k8s/pgadmin4 /data_k8s/postgres /data_k8s/addons /data_k8s/config
- Aller dans le dossier manifestes-k8s et lancer les manifestes
> cd ../manifestes-k8s
> kubectl apply -f ic-webapp/
> kubectl apply -f postgres/
> kubectl apply -f odoo/
> kubectl apply -f pg-admin/
- RDV dans le navigateur de votre machine, taper http://**<votre_ip_machine>**:**30080** pour finaliser le test




## Partie II
- Installation de Ansible sur le servuer Minikube
> yum -y install epel-release
> yum install -y python3
> curl -sS https://bootstrap.pypa.io/pip/3.6/get-pip.py | sudo python3
> /usr/local/bin/pip3 install ansible
> sudo yum install -y sshpass
