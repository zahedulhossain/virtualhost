
This project is forked from [RoverWire/virtualhost](https://github.com/RoverWire/virtualhost).  
If you're on Ubuntu then definitely use Roverwire's virtualhost script.  
I forked this to make it more usable for Arch Linux.

---

Virtualhost Manager
===========

Bash Script to create or delete apache/nginx virtual hosts on Arch Linux.

## Prerequisite ##

To fully automate the process on Arch Linux you need to:
1. Create a `sites-enabled/` and `sites-available/` directory under `/etc/httpd/conf/`
2. Add this line at the bottom of /etc/httpd/conf/httpd.conf file 
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
(you can copy it without the .sh extension):

```bash
$ sudo cp /path/to/virtualhost.sh /usr/local/bin/virtualhost
```


## Usage ##

Basic command line syntax:

```bash
$ sudo sh /path/to/virtualhost.sh [--create | --delete] [domain] [optional host_dir]
```

With script installed on /usr/local/bin

```bash
$ sudo virtualhost [--create | --delete] [domain] [optional host_dir]
```

### Examples ###

Create a new virtual host:

```bash
$ sudo virtualhost --create app.test
```
Create a new virtual host with custom directory name:

```bash
$ sudo virtualhost create app.test custom_dir
```
Delete a virtual host

```bash
$ sudo virtualhost --delete app.test
```

Delete a virtual host with custom directory name:

```bash
$ sudo virtualhost delete app.test custom_dir
```
