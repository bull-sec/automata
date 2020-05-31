# Automata.sh

Just a little script that we put together in BASH to help automate our initial note taking and our scanning with `nmap`. 

- Creates initial directories
- Performs `nmap` scan(s)
- Parses `nmap` results and generates a basic notes template

`Usage: ./automata.sh /path/to/target/file.txt /output/`

Handy way to use it is to add the script as an alias in your `.bashrc` file then you can run it inside a new directory.

```bash
$ mkdir /home/user/Target

$ cd /home/user/Target

$ echo "127.0.01" > target.txt 

$ automata target.txt .

Automata (the glorifed wrapper) v0.1

1. Just Create Directories
2. Do Quick Nmap Scans
3. Do Full Nmap Scans
4. Exit

Enter choice [ 1 - 4]:  
```

It's provided without warranty, so if it somehow breaks your machine we're not responsible. Feel free to steal this code and tweak it to your hearts content.

*Sample Notes.md*

```
# Target - 127.0.0.1

*Open Ports*

- 80
- 3306

*Nmap Results (clipped)*

\```
80/tcp   open  http    syn-ack Apache httpd 2.4.43 ((Debian))
3306/tcp open  mysql   syn-ack MySQL 5.5.5-10.3.22-MariaDB-1
\```


## Target Notes

### 80

### 3306


```

> Note: ignore the \ on the "Nmap Results (clipped)" section above, that's only there because rendering Markdown inside Markdown is awkward. 


--- 


TODO:

- [ ] Add more `nmap` scan variations

- [ ] Add option to hide output/increase verbosity

- [ ] Implement some basic fuzzing/scanning/banner-grabbing for detected HTTP/S servers

- [ ] Make menu persistent (ask to continue scanning after completion)

- [ ] Allow for multiple scans (from list of hosts)
