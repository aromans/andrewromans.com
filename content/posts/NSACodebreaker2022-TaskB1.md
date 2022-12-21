---
title: "NSACodebreaker2022 - TaskB1"
topic: "general"
tags: ["reverse-engineering", "web-analysis"]
prev: "http://localhost:1313/posts/nsacodebreaker2022-taska2"
next: "http://localhost:1313/posts/nsacodebreaker2022-taskb2"
date: 2022-12-20T11:37:37-05:02
draft: true
---

# Table of Contents
1. [Task A1](http://localhost:1313/posts/nsacodebreaker2022-taska1)
2. [Task A2](http://localhost:1313/posts/nsacodebreaker2022-taska2)
3. [Task B1](#task-b1)
	- [Solution](#solution)
4. [Task B2](http://localhost:1313/posts/nsacodebreaker2022-taskb2/)
5. [Task 5](http://localhost:1313/posts/nsacodebreaker2022-task5/)
6. [Task 6](http://localhost:1313/posts/nsacodebreaker2022-task6/)
7. [Task 7](http://localhost:1313/posts/nsacodebreaker2022-task7/)
8. [Task 8](http://localhost:1313/posts/nsacodebreaker2022-task8/)
9. [Task 9](http://localhost:1313/posts/nsacodebreaker2022-task9/)

## Task B1

- - -
###### The attacker left a file with a ransom demand, which points to a site where they're demanding payment to release the victim's files.

###### We suspect that the attacker may not have been acting entirely on their own. There may be a connection between the attacker and a larger ransomware-as-a-service ring.

###### Analyze the demand site, and see if you can find a connection to another ransomware-related site.
- - - 

### Solution

Opening up the ransom note from the attacker, the note reads:

```
Your system has been breached by professional hackers.  Your files have been encrypted, but they are safe.
Visit https://abmnrieyrwomcitk.unlockmyfiles.biz/ to find out how to recover them.
```

When visiting the website we are introduced to a glowing white page with a header labeled `Ransom Me This`, the supposed `ransomware-as-a-service ring`. The note details that all files, databases, application files and more were encrypted with so called `military-grade` algorithms. 

The note goes onto to let us know how many days we have left before our encryption key is deleted and how much money to send the attackers in the form of `RansomCoin`. 

Opening up the developer console, we can take a look around this web page to see if there is any evidence that was not hidden that can provide details about this `RansomMeThis` group.

For this challenge, there are two ways to go about finding the information we need. If you go into the `Debugger` tab of the developer console, one will find a `connect.js` file that requires some Reverse Engineering to determine what is happening. The gist is that this file has arrays that have been rotated incorrectly. The file then appropriately shifts the array so all the elements are in the correct index, and then pieces together a url with mathematically calculated indices in the correctly shifted array. 

The second way, and way easier method, is to head over to the `Network` tab of the developer console. Ensuring that the `All` option is selected and pressing refresh will provide you with any incoming and outgoing requests this web page is receiving. 

Most of the requests are relatively common, however one request in particular will stand out. The `File` section will show a query: `demand?cid=88599`. Looking at the response of this request shows a returned `JSON` file with the following contents:

```json
{"address":"tq0D21LYVZji4ztEGOVK7w","amount":5.657,"exp_date":1645620962}
```

This data shows the RansomeCoin wallet we were told to deposit the ransom as well as the amount of the request ransom! And to provide icing on the cake, looking at the `Initiator` field of the request shows that this request is coming from the above `connect.js` script itself! 

Taking a quick look at the `domain` this information is being requested from shows the following:

```
https://zgoxzopogsqkolvv.ransommethis.net/demand?cid=88599
```

I think we have found our `ransomware-as-a-service` ring webpage! We are now one step closer.

The correct answer:

`https://zgoxzopogsqkolvv.ransommethis.net`

![Task B1 Badge](/posts/badgeb1.png "Task B1 Badge")

- - -