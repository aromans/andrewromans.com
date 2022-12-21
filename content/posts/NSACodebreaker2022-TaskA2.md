---
title: "NSACodebreaker2022 - TaskA2"
topic: "general"
tags: ["computer-forensics", "packet-analysis"]
prev: "http://localhost:1313/posts/nsacodebreaker2022-taska1"
next: "http://localhost:1313/posts/nsacodebreaker2022-taskb1"
date: 2022-12-20T11:37:37-05:01
draft: true
---

# Table of Contents
1. [Task A1](http://localhost:1313/posts/nsacodebreaker2022-taska1)
2. [Task A2](#task-a2)
	- [Solution](#solution)
3. [Task B1](http://localhost:1313/posts/nsacodebreaker2022-taskb1/)
4. [Task B2](http://localhost:1313/posts/nsacodebreaker2022-taskb2/)
5. [Task 5](http://localhost:1313/posts/nsacodebreaker2022-task5/)
6. [Task 6](http://localhost:1313/posts/nsacodebreaker2022-task6/)
7. [Task 7](http://localhost:1313/posts/nsacodebreaker2022-task7/)
8. [Task 8](http://localhost:1313/posts/nsacodebreaker2022-task8/)
9. [Task 9](http://localhost:1313/posts/nsacodebreaker2022-task9/)

## Task A2

- - -
######  Using the timestamp and IP address information from the VPN log, the FBI was able to identify a virtual server that the attacker used for staging their attack. They were able to obtain a warrant to search the server, but key files used in the attack were deleted.

######  Luckily, the company uses an intrusion detection system which stores packet logs. They were able to find an SSL session going to the staging server, and believe it may have been the attacker transferring over their tools.

######  The FBI hopes that these tools may provide a clue to the attacker's identity  
- - -

### Solution

For this task, we were provided a pcap file and the provided server files retrieved from their search warrant. The goal is to determine the attacker's identity, so the first thing I decided to do was look through the collected server files to see if there was any indicators of their name or online identifiers. 

Of course it wasn't going to be that easy. Though there was nothing that indicated what their id was, there were some files located in the root directory that could be prove useful! Those files were:

  - .cert.pem file 
  - runwww.py script
  - And some lovely rabbit holes in the .cache folder

The `runwwww.py` script is a great indicator of what the attacker was doing in order to transfer files to the target machine. This could prove useful information for this task and in future tasks (*hint hint*). 

The `.cache` folder is a great way to spin your wheels without actually getting anywhere. Though provides an interesting game of hide and seek - the value to this specific task is minimal.

Lastly, the `.cert.pem` file is probably one of the most important files we could have found, but first we need to know what it was used for. Which leads me back to the `runwww.py` script. 

A quick skim of the `runwww.py` script without looking at the code will show a comment at the top that states:

`# This script will create an anonymous, secure, temporary web server to transfer files over HTTPS.`

So we now know that the attacker used this file to anonymously and securely attempt to transfer files to the target machine once compromised. Digging a little further down in the code will show that the attacker is making use of the `openssl` library to encrypt the traffic using tls, and luckily for us has hard coded the name of the cert that helps perform this encryption! 

If you are following me so far, I'm sure you will guess that the hard coded filename is `.cert.pem`. 

```python
certfile = '.cert.pem'
```

At this point, I think I am comfortable enough to open up the `pcap` file in Wireshark. Based on our previous research, we already know that the data in this `pcap` file will be encrypted, however since we have the `cert.pem` file - we can add that decryption option in the `tls` section of Wireshark to decrypt the tls traffic to reveal any secrets the attacker tried to keep hidden!

Like magic, all that was once encrypted is now revealed for our peering eyes! The first thing that I noticed was the `GET` request for `tools.tar`. 
A quick selection of the `follow tls stream` option in Wireshark will show us a lot of data that is seemingly nonsense. However, the data does actually have some structure. 

Since the attacker is transferring data from a compressed package, it will need to transfer all of the files stored within that compressed package. This will also give us insight as to what files exist within this `tools` package. 

We can see that generally the package is revealed in the format of `tools/<application here>` and is then followed by the content that exists in the file. 

For example, the first item in the `tools.tar` package that is transferred is:

`tools/busybox`

Which is then followed by the `ELF` header and what can be assumed as the binary data encoded as `ascii` text. So we know this package contains the `busybox` binary, which if we look up online is a `"software suite that provides several Unix utilities in a single executable file"`. 

Though I'm sure understanding the tools in this package are important (*and they are, hint hint*) for future tasks - this task asks us to find the identity of the attacker. 

Lucky for us, there is one revealing aspect of these transfers - and that usually involves the "username" of the user on the computer that is performing the transfer. Usually following not far from the file transfer itself. Of which, if we look around each `tools/<application here>` within the `tls stream`, we can see one consistent value. 

`AlertSadWound`

This tells us that the attacker goes by the screen name of `AlertSadWound`. A little OSINT might help us find who goes by this screen name, as most people tend to reuse the same screen name multiple times throughout their life. I know I do. 

The correct answer:

`AlertSadWound`

![Task A2 Badge](/posts/badgea2.png "Task A2 Badge")

- - -