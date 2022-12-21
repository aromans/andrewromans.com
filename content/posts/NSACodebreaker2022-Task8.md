---
title: "NSACodebreaker2022 - Task8"
topic: "general"
tags: ["reverse-engineering", "cryptography"]
prev: "http://localhost:1313/posts/nsacodebreaker2022-task7"
next: "http://localhost:1313/posts/nsacodebreaker2022-task9"
date: 2022-12-20T11:37:37-05:07
draft: true
---

# Table of Contents
1. [Task A1](http://localhost:1313/posts/nsacodebreaker2022-taska1)
2. [Task A2](http://localhost:1313/posts/nsacodebreaker2022-taska2)
3. [Task B1](http://localhost:1313/posts/nsacodebreaker2022-taskb1/)
4. [Task B2](http://localhost:1313/posts/nsacodebreaker2022-taskb2/)
5. [Task 5](http://localhost:1313/posts/nsacodebreaker2022-task5/)
6. [Task 6](http://localhost:1313/posts/nsacodebreaker2022-task6/)
7. [Task 7](http://localhost:1313/posts/nsacodebreaker2022-task7/)
8. [Task 8](#task-8)
	- [Solution](#solution)
9. [Task 9](http://localhost:1313/posts/nsacodebreaker2022-task9/)

## Task 8

- - -
###### You're an administrator! Congratulations!

###### It still doesn't look like we're able to find the key to recover the victim's files, though. Time to look at how the site stores the keys used to encrypt victim's files. You'll find that their database uses a "key-encrypting-key" to protect the keys that encrypt the victim files. Investigate the site and recover the key-encrypting key.
- - -

### Solution

We have been tasked to find the `key-encrypting-key` that their database uses to encrypt the encryption keys used against the victims. In order to do this - we first need to understand what is generating the keys for this `ransomware-as-a-service` website. We can make use of the server source code we've collected in previous tasks.

Looking at the source code, there are two functions: `lock` and `unlock`. The `lock` function runs a subprocess by executing a `keyMaster` binary located in the path `/opt/keyMaster/`. This returns the generated key in plain text to the user. The `unlock` function makes use of the same binary, however this time taking in an object as a `receipt` - which I can assume provides the key back in plain text so they can decrypt the victims files... maybe.

So to find the `key-encrypting-key`, we will have to dig into the `binary` that is being used to generate the keys themselves first, and find the logic that generates the key and stores the key into their databases. However, before we can do that we must retrieve the `binary`! 

Playing around on the website, the admin portal offers us to fetch the key generation logs. Doing so provides us with a url that should look fairly exploitable! 

```
/aibtrqzgecledjgo/fetchlog?log=/opt/ransommethis/log/keygeneration.log
```

For those who don't know, this is an opportunity to test for an `LFI` exploit; or `Local File Inclusion` exploit. This allows us to enter in an arbitrary path that the web server can then go about retrieving for us. If the web server trusts our input and doesn't check for any manipulation that is. Which we know the web server doesn't since we have the source code! ;)

However, to test if this works we can try accessing the passwd file: `/etc/passwd`. 

```
/aibtrqzgecledjgo/fetchlog?log=../../../../../../etc/passwd
```

Doing this gives us the following prompt:

*We're going to break the kayfabe here a bit. Congratulations, you found a file disclosure bug in our site! We're not going to actually give you unfettered access to our files, but you can use it to access the files you need to complete Task 8. Keep going!*

This is fantastic news! Though we don't get access to `/etc/passwd` we DO know where the binary file is! 

```
/aibtrqzgecledjgo/fetchlog?log=../../../../../../opt/keyMaster/keyMaster
```

And we can grab some of the database files as well

```
/aibtrqzgecledjgo/fetchlog?log=../../../../../../opt/ransommethis/db/user.db
/aibtrqzgecledjgo/fetchlog?log=../../../../../../opt/ransommethis/db/victims.db
```

Now that we have the binary, we start with some simple static analysis. First and foremost, lets start with the simple, yet powerful, `strings` command.

- go1.18.3 | Looks like this was made with GO version 1.18.3

Besides discovering that this is a `Go` compiled binary - the remaining values in strings was pretty much useless without context. So now we can move forward to some dynamic analysis. 

My initial attempts took me down the road using Ghidra - I spent a whole day adjusting variables and following the function rabbit hole; but didn't get very far.

After a bit of research, I discovered how Golang Binaries are compiled, and found that there is a lot of remaining library functions included that obscure the code we are actually interested in reversing. 

I came across a couple of great resources that were very helpful and insightful on reversing Go binaries. I'll paste their links below for those who are interested.

```
1. https://www.youtube.com/watch?v=J2svN8h21oo

2. https://www.youtube.com/watch?v=_cL-OwU9pFQ
```

Though both videos were of great help, the second video shined light on how using IDA free could make this task a little bit easier. Ghidra is a fantastic tool and my daily driver, but I found using IDA free to reverse this particular binary made life a little bit easier.

My first plan of attack was to understand where everything was located. I read through each function and tried to figure out what exactly each function was trying to accomplish. After several hours of work - I was able to rename most of the functions to their associated goal and their virtual address. Of course - I still had questions and there were quite a few unknowns, but I had a general layout of how things were functioning.

```
0x5b99b2 -> main_main
0x5b966a -> main_unlock
0x5b89a0 -> main_getReceipt
0x5b94ca -> main_getKeyPaymentPair
0x5b85ea -> main_aesCryption
0x5ba46f -> main_pbkdf2Cryption
0x5b876f -> main_getEncryptionKey
0x5b820A -> main_oJBq2ENUTYQ
0x5b8b12 -> main_lock
0x5b9346 -> main_lock_func1
0x5b92e6 -> main_lock_func2
0x5b97ea -> main_creditUpdate
0x5b89aa -> main_getReceipt
0x5b8ae0 -> main_getReceipt_rsa??
0x5b93af -> main_getEncodedUUID
```

I decided to spend some time dynamically running the binary through GDB and following stack pointers and registers. Understanding where the lock function is being called from, what is being encrypted, etc. 

After some time, I narrowed down my search to the three following functions (I personally named up above): 

`main_getEncodedUUID, main_getEncryptionKey, and main_lock.`

With these three functions now targets in my scope, I decided to hop back in IDA, install golang on my computer, and reverse each function and write them into my own golang script. I figured this would help me better understand what the developers were thinking when writing this file and that having an easier way to tinker and execute the source code would come in handy down the line. (*Hint hint*)

After doing so - I was able to run my script, taking in similar inputs to the original binary, and end with an encrypted base64 key and plain text key similar to the ones being generated and stored by the keyMaster binary. 

=== My Script Output ===
```
2022-01-24T07:59:11-05:00
c5632680-248e-11ed-a29f-000c29df0279
2022-01-24T07:59:11-05:00
10101010101010101010101010101010
c5632680-248e-11ed-a29f-000c29df
16
[39 223 20 166 39 71 182 24 6 163 66 196 25 141 78 204]
J98UpidHthgGo0LEGY1OzKvVFpJZXqw3q08X/sRxAA4qW86hS1NrHNGzLRcNeS1ORcew7ncLhv3sf/iuQFZipQ==
```

=== My Code ===
```GO
package main

import (
	"fmt"
	"github.com/google/uuid"
	"encoding/hex"
	"golang.org/x/crypto/pbkdf2"
	"crypto/sha256"
	"strconv"
	"time"
	"crypto/rand"
	"crypto/cipher"
	"crypto/aes"
	"encoding/base64"
)

func encodeHex(dst []byte, uuid uuid.UUID) {
	hex.Encode(dst[:], uuid[:4])
	dst[8] = '-'
	hex.Encode(dst[9:13], uuid[4:6])
	dst[13] = '-'
	hex.Encode(dst[14:18], uuid[6:8])
	dst[18] = '-'
	hex.Encode(dst[19:23], uuid[8:10])
	dst[23] = '-'
	hex.Encode(dst[24:], uuid[10:])
}

func Pbkdf2Cryption() []byte {
	staticKey := "ZIDZgV2L2XaI3xPfaTJyIlFctbl0eVx4IZh4pySrGL8="
	salt, _ := base64.StdEncoding.DecodeString(staticKey)

	// Original code has some loop that goes until we get the below value!

	password := "Xzpm1z9BF9/R0ZwqhUpbfxWYc/C8sFkQ2yeh7oLDqDBUnwjH2C8hHbmbjsDa/WJuWbdCOjIueqvKSfmNU1NGzA=="
	iter := 4096
	key_len := 32
	dk := pbkdf2.Key([]byte(password), []byte(salt), iter, key_len, sha256.New)
	return dk
}

func SomeOtherMainFunc() []byte {
	val := []byte{0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10,0x10}
	fmt.Println(hex.EncodeToString(val[:]))
	return val
}

func GetEncryptionKey(encodedUUID []byte) {
	key := Pbkdf2Cryption()
	block, _ := aes.NewCipher(key)

	_binChar := SomeOtherMainFunc()
	appendedVal := append(encodedUUID[:len(encodedUUID) - 4], _binChar...)

	fmt.Println(string(appendedVal))

	ciphertext := make([]byte, aes.BlockSize+len(appendedVal))
	iv := ciphertext[:aes.BlockSize]
	n, _ := rand.Read(iv)

	fmt.Println(n)
	fmt.Println(iv)

	stream := cipher.NewCFBEncrypter(block, iv)
	stream.XORKeyStream(ciphertext[aes.BlockSize:], appendedVal)

	fmt.Println(base64.StdEncoding.EncodeToString(ciphertext))
}


func main() {
	fmt.Println("2022-01-24T07:59:11-05:00")
	seq, _ := strconv.Atoi("1643029151")
	uuid.SetClockSequence(seq)
	uuid, _ := uuid.NewUUID()
	var buf [36]byte
	encodeHex(buf[:], uuid)
	encodedUUID := string(buf[:])

	fmt.Println(encodedUUID)

	current_time, _ := time.Parse(time.RFC3339, "2022-01-24T07:59:11-05:00")
	formatted_time := current_time.Format("2006-01-02T15:04:05Z07:00")

	fmt.Println(formatted_time)

	GetEncryptionKey(buf[:])
}
```

Now that I had a functioning `lock` function of the keyMaster binary, it was time to take an even closer look for the `key-encrypting-key`. I realized that the most obvious target would be the `Pbkdf2Cryption()` method. This method was the one that returns a constant key that is never changing, and being used to create an AES Block Cipher. 

Since I already had the code written in my own script (excluding the weird loop that generated the base64 password string), all I had to do was take the output of the byte string and convert to base64 to get the following output: 

```
<removed>
DATA: 
sg1pOYDEBz6asTUKv0jOUL2w+jgnokcbi0j0WSDpWi4=
<removed>
```

=== The Function ===
```Go
func Pbkdf2Cryption() []byte {
    staticKey := "ZIDZgV2L2XaI3xPfaTJyIlFctbl0eVx4IZh4pySrGL8="
    salt, _ := base64.StdEncoding.DecodeString(staticKey)

    // Original code has some loop that goes until we get the below value!

    password := "Xzpm1z9BF9/R0ZwqhUpbfxWYc/C8sFkQ2yeh7oLDqDBUnwjH2C8hHbmbjsDa/WJuWbdCOjIueqvKSfmNU1NGzA=="
    iter := 4096
    key_len := 32
    dk := pbkdf2.Key([]byte(password), []byte(salt), iter, key_len, sha256.New)

    fmt.Println("DATA: ")
    fmt.Println(base64.StdEncoding.EncodeToString(dk)) // The key-encrypting key
  
    return dk
}
```

Plugging this decoded base64 string into the website shows that we did indeed find the `key-encrypting-key` that we were looking for! Its nice to see all your hard work come together! :) 

The correct answer:

`sg1pOYDEBz6asTUKv0jOUL2w+jgnokcbi0j0WSDpWi4=`

![Task 8 Badge](/posts/badge8.png "Task 8 Badge")

- - -