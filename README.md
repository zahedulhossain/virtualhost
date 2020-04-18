
This project is forked from [RoverWire/virtualhost](https://github.com/RoverWire/virtualhost).  
If you're on Ubuntu then definitely use Roverwire's virtualhost script.  
I forked this to make it more usable for Arch Linux and added some extra option.

---

Virtualhost Manager
===

Bash Script to manage apache/nginx virtualhosts on Arch Linux.


## Prerequisite ##

To fully automate the process on Arch Linux you need to:
1. Create a `sites-enabled/` and `sites-available/` directory under `/etc/httpd/conf/`
2. Add the following line at the bottom of `/etc/httpd/conf/httpd.conf`
```
'Include conf/sites-enabled/*.conf'
```


## Installation ##

1. Download the script
2. Add permission to execute:

```
$ chmod +x /path/to/virtualhost.sh
```

3. If you want to use the script globally, then copy the file to your /usr/local/bin directory,  
(copy it without the .sh extension to get a more command like feel):

```bash
$ sudo cp /path/to/virtualhost.sh /usr/local/bin/virtualhost
```


## Usage ##

Basic command line syntax:

```bash
$ sudo sh /path/to/virtualhost.sh [create | remove] [domain] [optional host_dir]
```

With script installed on /usr/local/bin

```bash
$ sudo virtualhost [create | remove] [domain] [optional host_dir]
```

### Examples ###

Show all virtualhosts:

```bash
$ sudo virtualhost all
```

Show all active virtualhosts:

```bash
$ sudo virtualhost list
```

Create a new virtualhost:

```bash
$ sudo virtualhost create app.test
```
Create a new virtualhost with custom directory name:

```bash
$ sudo virtualhost create app.test custom_dir
```
Delete a virtualhost

```bash
$ sudo virtualhost remove app.test
```

Delete a virtualhost with custom directory name:

```bash
$ sudo virtualhost remove app.test custom_dir
```

Enable a virtualhost:

```bash
$ sudo virtualhost enable hostname.test
```

Disable a virtualhost:

```bash
$ sudo virtualhost disable hostname.test
```