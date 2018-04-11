# ON REGISTRY KNOWN AS 
ziggingdock/docker-generic-webdev:[tag] (tag corresponds to branch-name)

---

# DESCRIPTION
Generic PHP7 environment. Including:  
* Ubuntu 16.04 LTS
* Apache2
* PHP7 + XDebug

For basic projects you can simply use it "as is".  
For more complex projects you can include it as a base-image in a Dockerfile distributed with the project ("FROM").

---

# USAGE

## Testing the image
You can easily ensure that the container is working. Spin up container with:  
```docker run -tid -p 8000:80 [image]```  
...and then access http://localhost:8000  

## Use as-is 
The image comes with a vhost listening to "docker-web" hostname.  
Just make sure to add this to your hosts-file:  
```127.0.0.1 docker-web```  

When running your container you simply need to mount your local docroot at /var/www/docker-web. Like:  
```docker run --name mycontainer -tid -p 8000:80 -v /your/docroot/path:/var/www/docker-web [imagename]```
Now you can access:  
http://docker-web:8000

## Use as base-image for more complex projects
Simply include this image as base-image in a Dockerfile which you distribute along with your project.  
Include it in the "FROM" statement and ensure to include a vhost too (```ADD /local/vhost /etc/apache2/sites-enabled/some.vhost.conf```)  
This approach is relevant in case you need further tweaking apart from what the generic image provides.  

### Project structure
```
/
  home/
    someuser/
      project/
        Dockerfile (*)
        myproject.whatever.com-vhost.conf (**)
        htdocs/
          index.php
        includes/
```

### Dockerfile (*)
```
FROM [this image]

RUN mkdir /var/www/myproject
ADD ./myproject.whatever.com-vhost.conf /etc/apache2/sites-enabled/myproject.whatever.com-vhost.conf
VOLUME /var/www/myproject
```


### Vhost (myproject.whatever.com-vhost.conf) (**)
Note: Make sure your DNS record has been created   
The files are mounted when starting container  
If you need xdebug: See further down!  

```
<VirtualHost *:80>
    ServerName myproject.whatever.com

    DocumentRoot "/var/www/myproject/htdocs"

    <Directory "/var/www/myproject/htdocs">
        Options FollowSymLinks Indexes
        AllowOverride None
        
        # --- Apache 2.4 syntax ---
        Require all granted
    </Directory>

    php_value include_path ".;/var/www/myproject/includes"
    php_value error_reporting 32767 # For dev environment
</VirtualHost>
```

### XDebug
Xdebug is included in the container.  
To make use of it you need to do a couple of things.  
Source: https://medium.com/@pablofmorales/xdebug-with-docker-and-phpstorm-786da0d0fad2  

1) Enable xdebug-module for the webserver in the container. You need the following in your Dockerfile to enable the module:  
```RUN ln -s /etc/php/7.2/mods-available/xdebug.ini /etc/php/7.2/apache2/conf.d/20-xdebug.ini``` 

2) Set at couple of env-vars on your docker image.  
Notice: ```PHP_IDE_CONFIG``` is required by PhpStorm and can be left out if you use another IDE (which might require some other envvars).  

docker-compose.yml (set for the service):  
```
environment:
   XDEBUG_CONFIG: "remote_host=[IP of your host]"
   PHP_IDE_CONFIG: "serverName=[SomeName]"
```

```XDEBUG_CONFIG="remote_host=[IP of your host]"``` is used for defining which IP xdebug should connect back to.  
I suggest you set ```XDEBUG_CONFIG: "remote_host=$DOCKER_HOST_ADDR"``` and then define this envvar in your OS. It seems like these might be recommended values:  
```
OSX: docker.for.mac.localhost (special DNS name for OSX)  
Windows: 10.0.75.1 (bridge on Windows)  
```


```PHP_IDE_CONFIG: "serverName=[SomeName]"``` is required when using PhpStorm for specifying which path-mapping the IDE should be using. Can be left out if you use a different IDE! 

3) Configure xdebug. Can also be done by injecting settings into xdebug.ini but in this case we append it to the vhost.  
Notice that the syntax is slightly different if you decide to use xdebug.ini (using "=").  
```
php_value xdebug.remote_enable 1
php_value xdebug.remote_autostart 1
php_value xdebug.remote_connect_back 0
php_value xdebug.remote_handler dbgp
php_value xdebug.profiler_enable 0
php_value xdebug.profiler_output_dir "/path/for/profiler/files/if/enabled"
php_value xdebug.remote_port 9000
```

4) IDE config. This example is for PhpStorm v2017.2.2.  
4a) Language -> PHP -> Debug -> Xdebug section: Enable Xdebug on port 9000 (or what is used in xdebug.remote_port directive). Allow external connections.  
4b) Language -> PHP -> Servers: Add a set of settings. The "Name" must match the one used in the PHP_IDE_CONFIG envvar (in this example: SomeName). Add a mapping between the location of document root on your host and to the absolute path on the docker image. Like e:\phpstormprojects\project\htdocs --> /var/www/awesomeproject. Host is localhost:9000.  


Don't forget to click the "start listening" button to make sure your IDE is in fact listening. Found in the topbar. 

