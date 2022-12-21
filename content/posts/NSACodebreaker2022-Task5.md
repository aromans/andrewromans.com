---
title: "NSACodebreaker2022 - Task5"
topic: "general"
tags: ["reverse-engineering", "cryptography"]
prev: "http://andrewromans.com/posts/nsacodebreaker2022-taskb2"
next: "http://andrewromans.com/posts/nsacodebreaker2022-task6"
date: 2022-12-20T11:37:37-05:04
---

# Table of Contents
1. [Task A1](http://andrewromans.com/posts/nsacodebreaker2022-taska1)
2. [Task A2](http://andrewromans.com/posts/nsacodebreaker2022-taska2)
3. [Task B1](http://andrewromans.com/posts/nsacodebreaker2022-taskb1/)
4. [Task B2](http://andrewromans.com/posts/nsacodebreaker2022-taskb2/)
5. [Task 5](#task-5)
	- [Solution](#solution)
6. [Task 6](http://andrewromans.com/posts/nsacodebreaker2022-task6/)
7. [Task 7](http://andrewromans.com/posts/nsacodebreaker2022-task7/)
8. [Task 8](http://andrewromans.com/posts/nsacodebreaker2022-task8/)
9. [Task 9](http://andrewromans.com/posts/nsacodebreaker2022-task9/)

## Task 5

- - -
###### The FBI knew who that was, and got a warrant to seize their laptop. It looks like they had an encrypted file, which may be of use to your investigation.

###### We believe that the attacker may have been clever and used the same RSA key that they use for SSH to encrypt the file. We asked the FBI to take a core dump of ssh-agent that was running on the attacker's computer.

###### Extract the attacker's private key from the core dump, and use it to decrypt the file.

###### Hint: if you have the private key in PEM format, you should be able to decrypt the file with the command openssl pkeyutl -decrypt -inkey privatekey.pem -in data.enc
- - -

### Solution

Since the FBI knew who hosted the domain, they got a warrant and seized their laptop. They were able to capture a core dump of ssh-agent running on the attacker's computer and were suspicious that the attacker used the same RSA key for ssh to encrypt the file. That being the case, we are provided an `ssh-agent` binary, the `core` dump file, and an encrypted file: `data.enc`.

There are multiple tools to help reverse engineer the binary to extract the ssh key, however I chose to use `Binary Ninja and GDB` to solve this task. Their free version combined with good note taking proved to be just enough to figure out a solution.

For starters, this task took me down a lot of various rabbit holes! My notes look like Charlie from It's Always Sunny in Philadelphia! However, after lots... and lots.... and lots of digging, it boiled down to a couple of leads and reading source code.

Doing a little bit research on openssl, openssh, and extracting private keys - I came across an old blog from 2009. This post talked about extracting the E, P, and Q values of the private RSA key from RAM within the core dump of ssh-agent. This required knowledge of the source code, understanding the location of byte size of the variables, and a trick to locate some of the identifiers in memory.

Looking at the `ssh-agent.c` source code, line 149 hosts a char array that is labeled `socket_name`. This makes a great indicator as we will be able to read the string in clear text! We can then use the address for that value to subtract the number of bytes necessary to reach the struct holding our RSA private key! 

Though great in theory doing so in application proved to be a bit more of a struggle. Though I was able to find the struct that held the RSA private key information, the values that should hold the addresses for E, P, and Q were completely empty. 

I decided I needed to create two ssh-agent core dumps of my own in order to compare and contrast with the one extracted from the attacker. Confirming that the RSA variable data (p, q, n, e, etc) were all completely cleared out. 

So why is this?

With a little more google-fu, I found an update that discussed the addition of `shielding` the private key. Digging deeper into the `shielding` feature, I found articles discussing how openssh used to simply store private keys directly in ram for everyone to see. Since this is clearly a major security flaw, they decided to shield the private keys and store the shielded values in ram instead and only unshielding the key when it is needed. This is done by using a randomly generated 16kb prekey value, SHA512 hashes, serialization, and AES256 assymetric block cipher encryption! Wow..

Well if there is a will, there is a way... Luckily, during my research - I came across an article on someone who has already done some research on exploiting shielded keys. If you are able to get the values of the shielded private key and prekey and store them as data files, one can use `GDB` to create their our `key` struct with that information and pass the struct to the `sshkey_unshield_private()` function. Ensuring that there is a breakpoint before the `sshkey_free()` function will stop the now `unshielded private key` from disappearing and leaving it open for snatching! 

Once collecting the private key in plaintext, I had to convert the Openssh format to an rsa pem format using the following function:

```
ssh-keygen -p -m pem -f [private key file location]
```

Then, plug the key into the openssl function they provided:

```
openssl pkeyutl -decrypt -inkey privatekey.pem -in data.enc
```

And we officially have the decoded file we've been looking for!

```
# Netscape HTTP Cookie File
zgoxzopogsqkolvv.ransommethis.net	FALSE	/	TRUE	2145916800	tok	eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE2NTI1NjA2ODcsImV4cCI6MTY1NTE1MjY4Nywic2VjIjoiSDBidzM5N09jUHgyMlZBa1NQSTd3c3ZaNXFuZGlTakEiLCJ1aWQiOjIyNDkyfQ.QgxdO3-_ZI3InW90GiQvOjddffZOSboRVNGWohWdWnM 
```

Which just so happens to have a yummy cookie for us. Fortuitous to have now that we can access the login page!

The correct answer:

`eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE2NTI1NjA2ODcsImV4cCI6MTY1NTE1MjY4Nywic2VjIjoiSDBidzM5N09jUHgyMlZBa1NQSTd3c3ZaNXFuZGlTakEiLCJ1aWQiOjIyNDkyfQ.QgxdO3-_ZI3InW90GiQvOjddffZOSboRVNGWohWdWnM`

![Task 5 Badge](/posts/badge5.png "Task 5 Badge")

#### Sources

- https://vnhacker.blogspot.com/2009/09/sapheads-hackjam-2009-challenge-6-or.html
- https://stackoverflow.com/questions/68160/is-it-possible-to-get-a-core-dump-of-a-running-process-and-its-symbol-table
- https://xorhash.gitlab.io/xhblog/0010.html
- https://security.humanativaspa.it/openssh-ssh-agent-shielded-private-key-extraction-x86_64-linux/
- https://tomeko.net/online_tools/hex_to_file.php?lang=en
- https://github.com/openssh/openssh-portable
- https://github.com/openssl/openssl

- - -