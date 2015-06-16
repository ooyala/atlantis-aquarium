atlantis-aquarium
=================

Atlantis in a Vagrant VM!  Excellent for testing.

# Requirements
* git
* ruby 1.9.1 or later
* vagrant 1.7.2 or later

# Bootstrap

The following steps are needed in order to bootstrap atlantis aquarium. They are recorded in **makeitso.sh** script as well. 

Control is primarily through the controller, **bin/atlantis-aquarium** (which should probably become a gem or other easily-installable package at some point).  

```
$bin/atlantis-aquarium

Usage:
  atlantis-aquarium build   [<component>...] [options] [-C | --compile] [-I | --image]
  atlantis-aquarium start   [<component>...] [options]
  atlantis-aquarium restart  <component>...  [options]
  atlantis-aquarium stop     <component>...  [options]
  atlantis-aquarium ssh     [<component>]    [options]
  atlantis-aquarium atlantis [--] [<argument>...]
  atlantis-aquarium provision
  atlantis-aquarium register-components
  atlantis-aquarium base-cluster
  atlantis-aquarium build-layers  [--base] [--builder]
  atlantis-aquarium nuke-system

Options:
  -C, --compile  Only compile; don't build image or deploy
  -I, --image    Only compile and build Docker image; don't deploy
  -i, --instance Which instance of the component to act on [default: all]
  -h, --help     Show usage
```

## clone repos
First, create **$HOME/repos** folder and clone atlantis-aquarium repo under this folder. 
Then find **$HOME/repos/atlantis-aquarium/bin/clone-repos** script and run it; the script will clone several atlantis coomponents repos that 
aquarium needs into **$HOME/repos** folder

```
$cd $HOME/repos/atlantis-aquairum
$./bin/clone-repos

....

$ls $HOME/repos
atlantis-aquarium	atlantis-manager	atlantis-supervisor	hello-atlantis
atlantis-builder	atlantis-router		go-docker-registry	

```

## provision

Now it is time to bring up and provision vagrant VM. the *provision* subcommand will spin up vagrant VM called *aquarium* and install go, setup docker, etc.  
This step should be done with a fresh VM.
```
$bin/atlantis-aquarium provision

.............

$vagrant status
Current machine states:

aquarium                  running (virtualbox)

The VM is running. To stop this VM, you can run `vagrant halt` to
shut it down forcefully, or you can run `vagrant suspend` to simply
suspend the virtual machine. In either case, to restart it again,
simply run `vagrant up`.
```

## build and start atlantis components
Aquarium require following components. All but base-aquarium-image are services run in docker containers within the VM we just created; 
base-aquarium-image is a special target to build the base image that other components run inside.    

* **base-aquarium-imagec**; base docker image for every other components in this list 
* **zookeeper**; a single node zookeeper
* **registry**; https://github.com/ooyala/go-docker-registry 
* **builder**; https://github.com/ooyala/atlantis-builder
* **manager**; https://github.com/ooyala/atlantis-manager
* **router-internal**; https://github.com/ooyala/atlantis-router
* **router-external**; https://github.com/ooyala/atlantis-router
* **supervisor**; https://github.com/ooyala/atlantis-supervisor

*build* subcommand compile, build the container, and (re)start the given component. *build* take following options

```
 -C, compiles only; If an instance is given, only that instance will be compiled
 -I, compiles and builds container but doesn't restart.  If an instance is given, only that instance will be build.
```

to build and (re)start all the components;

```
$bin/atlantis-aquarium build
```

or, to build and (re)start a single component

```
$bin/atlantis-aquarium build <component-name>
```

## interact with the components
Once the components built, you can start/stop/restart or obtain ssh shell into the container 

- start: Ensure that the component is running.  If it is already running, it won't be restarted.

- restart: Restart the container.  If it is running, it will be stopped and then started; if not, it will just
  be started.  Note that this restarts the container, so any data stored within it will be lost.  (E.g.,
  restarting Zookeeper will destroy all metadata about the cluster.

- stop: Ensure that the component is not running.  If it is already stopped, no action is taking.

- ssh: ssh into the container for the given component/instance.  If no instance is given for supervisor or
  router, each instance will be ssh'd into in turn.  If no component is given, ssh into the Vagrant VM
  instead.

```
$bin/atlantis-aquairum start|stop|restart|ssh <component-name>
``` 
## build-layers
*build-layers* subcommand builds layers required for deploying.  Only needed for the simple builder, as aquarium used. it support following options:
 
* *--base* builds only the base image; 
* *--builder* builds only the language-specific layers (e.g., ruby1.9.3, go1.2).  Should be done when layers are modifed or the builder is restarted.

```
$bin/atlantis-aquairum build-layers [--base] [--builder]
``` 

## register-components 
*register-components* registers the supervisors, routers, etc. with the manager. Should be done once after all components are started, or after zookeeper is restarted.

```
$bin/atlantis-aquairum register-components
```

**Note:** you may be promoted to input LDAP username and/or password, just type enter to continue

## hello-world app
*base-cluster* set up a sample hello-go app and deploy it to supervisor.  It is useful as a test to ensure everything is working in aquarium. Should be done after all steps has been taken;

```
$bin/atlantis-aquairum base-culster
```
If everything works out nicely, you just launched your first atlantis app in aquarium. Now check it out.
```
$bin/atlantis-aquarium ssh supervisor

... ...

root@c5fb42cc6eb4:~# docker ps 
CONTAINER ID        IMAGE                                                                                COMMAND                CREATED             STATUS              PORTS                                                                                                                                                                                  NAMES
d62dc9dc237e        registry.aquarium/apps/hello-go1.2-6292411629e73234fd0ecd0ded43b1fd259dfa44:latest   "runsvdir /etc/servi   6 minutes ago       Up 6 minutes        0.0.0.0:61000->61000/tcp, 0.0.0.0:61100->61100/tcp, 0.0.0.0:61200->61200/tcp, 0.0.0.0:61300->61300/tcp, 0.0.0.0:61400->61400/tcp, 0.0.0.0:61500->61500/tcp, 0.0.0.0:61600->61600/tcp   hello-go1.2-629241-test-oAZOK9   


root@c5fb42cc6eb4:~# curl http://localhost:61000
<!DOCTYPE html><html><head><title>hello-go</title></head><body><pre>
Hello from Go /
</pre></body></html>
```
 
## Convenience wrapper for atlantis-manager CLI
*atlantis* subcommand will pass remaining arguments to the atlantis-manager cli run within the VM; this is
a convenience, e.g.
```
$bin/atlantis-aquarium atlantis list-env
```

## Clean up
*nuke.sh*, as the name suggested, tear down everything!

```
$./nuke.sh
```

#Known issues
While running *build* subcommand, sometimes it fails with error message like this
```
INFO[0024] Error getting container 2328b2d6de9727c41ad1dcf1f977057a1cedb15e65c466a01482c09576236618 from driver devicemapper: open /dev/mapper/docker-8:1-403558-2328b2d6de9727c41ad1dcf1f977057a1cedb15e65c466a01482c09576236618: no such file or directory 
```
This is caused by well known docker issue (https://github.com/docker/docker/issues/4036) where docker having a race condition in storage backend. Re-run the build normally will pass.  



