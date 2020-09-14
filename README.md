# Kubernetes + Vagrant Projesi

## Amaç
Proje amacı, proje geliştirme sürecinde oluşabilecek karmaşıklıkları en aza indirmek, geliştiricilere stabil bir ortam sağlamak ve üretim ortamlarında oluşabilecek sorunları en aza indirmektir.

## Bağımlılıklar
### j2 Python Komutu
Projeye ulaşmak için [buraya](https://www.vagrantup.com/downloads.html) tıklayabilirsiniz.

## Kullanım
Uygulamanın bütün kontrolü, "manage.sh" scripti yardımıyla sağlanmaktadır. Örnek kullanım aşağıda gösterilmiştir.

Tam kurulum
```bash
./manage.sh -o bundle-deploy --application-name awsome-app --k8s-namespace awsome-app --k8s-services "tcp:3000:3000" --k8s-env-variables "MYSQL_SCHEMA:awsome-app" --k8s-image yigitbasalma/awsome-app --db mysql --docker-registry yigitbasalma
```

**Not:** Kurulum sonrasında kubernetes master "192.168.40.20", node-1 "192.168.40.31" adresinde çalışacaktır.

Build ve deploy
```bash
./manage.sh -o deploy --application-name awsome-app --docker-registry yigitbasalma --k8s-namespace awsome-app
```

Parametreler konusunda detaylı yardım için, aşağıdaki komut çalıştırılabilir. Komut çıktısı örnek olarak verilmiştir.
```bash
[ghost@localhost 69371d6c6bd70706858283fd96fcc836]$ bash manage.sh help
Help for manage.sh;
    --operation:    Operation name. [infra-setup, build, k8s-setup, deploy, bundle-deploy]
        for infra-setup
            Infrastructure setup for lab. Run vagrant up, create k8s cluster with 1 master 1 node, get k8s credential.
        for build
            Run docker build in docker folder. Your application code must be in docker/app folder.
            Parameters:
                --application-name:     Application name for docker image.
            Optional parameters:
                --docker-registry:      Docker registry address for docker pull command. You must be logged in to remote registry.
        for k8s-setup
            Prepare your application to deploy k8s. Your all yaml files belongs to your application prepare dynamically.
            Parameters:
                --application-name:     Application name for deployment.
                --k8s-namespace:        Namespace for your environment.
                --k8s-services:         Application services. Syntax: "protocol:port:target-port;..."
                --k8s-env-variables:    Environment variables for application container. Syntax: "key:value;..."
                --k8s-image:            Image name for your application container.
        for deploy
            Deploy prepared yaml files to the project namespace
            Parameters
                --application-name:     Application name for deployment.
                --k8s-namespace:        Namespace for your environment.
            Optional parameters:
                --db:                   Database software name for your application. [mysql]
        for bundle-deploy
            Apply all other options sequentially.
```

## Yararlanılan Dökümanlar
[Vagrant with Kubernetes](https://kubernetes.io/blog/2019/03/15/kubernetes-setup-using-ansible-and-vagrant)
