---
title: "NSACodebreaker2022 - TaskA1"
topic: "general"
tags: ["log-analysis"]
next: "http://andrewromans.com/posts/nsacodebreaker2022-taska2"
date: 2022-12-20T11:37:37-05:00
---

# Table of Contents
1. [Task A1](#task-a1)
	- [Solution](#solution)
2. [Task A2](http://andrewromans.com/posts/nsacodebreaker2022-taska2)
3. [Task B1](http://andrewromans.com/posts/nsacodebreaker2022-taskb1/)
4. [Task B2](http://andrewromans.com/posts/nsacodebreaker2022-taskb2/)
5. [Task 5](http://andrewromans.com/posts/nsacodebreaker2022-task5/)
6. [Task 6](http://andrewromans.com/posts/nsacodebreaker2022-task6/)
7. [Task 7](http://andrewromans.com/posts/nsacodebreaker2022-task7/)
8. [Task 8](http://andrewromans.com/posts/nsacodebreaker2022-task8/)
9. [Task 9](http://andrewromans.com/posts/nsacodebreaker2022-task9/)

## Task A1 

- - - 
###### We believe that the attacker may have gained access to the victim's network by phishing a legitimate users credentials and connecting over the company's VPN. The FBI has obtained a copy of the company's VPN server log for the week in which the attack took place. Do any of the user accounts show unusual behavior which might indicate their credentials have been compromised? Note that all IP addresses have been anonymized.
- - -

### Solution

A quick skim through the logs shows that there is a lot of noise that makes finding suspicious activity a bit more complex. My first approach was to go through manually to pick out suspicious activity, such as the low hanging fruit of picking out failed login. However, failed logins can be a fairly regular accident that happens to almost everyone - which is hardly evidence for being suspicious, circumstantial at most.

The goal is to find defining evidence of someone who could be compromised. Looking through all of the logs - we are provided the timestamps of when a user logs in via the VPN and their duration of how long they were connected. In result, this allows us to also calculate when the time they disconnected from the VPN. 

So how can we use this to determine if someone was compromised?

If there is a user who logs in more than once on the same day, but has overlap in their log in times - this must mean the same user is logged into the same VPN twice. Though not necessarily a nail in the coffin, given the circumstance of being compromised and the fact this is not very common finding this sort of incident in our logs could be a very good indicator of which employee led to the compromise of the systems. 

Calculating all the times from the timestamps manually would not be fun at all, so I wrote a small python script to do this for me! I also included a few utility functions to help find any other information I so desired. 

```python
#!/usr/bin/python3

import time

file = open('vpn.log', 'r')
lines = file.readlines()

valid_attempt = []
invalid_attempt = []

logs = {}

def get_sec(time_str):
	t = time_str.split(' ')
	h, m, s = t[1].split(':')
	return int(h) * 3600 + int(m) * 60 + int(s)

def get_time_str(duration):
	return time.strftime('%H:%M:%S', time.gmtime(duration))

i = 0
for line in lines:
	if (i == 0):
		i = i + 1
		continue

	if ("LDAP invalid" in line):
		invalid_attempt.append(line.split(','))
	else:
		valid_attempt.append(line.split(','))

	tokens = line.split(',')

	name = tokens[1]
	start_time = tokens[2]

	if (tokens[3] == ''):
		duration = 0
	else:
		duration = int(tokens[3])
	active = tokens[5]
	auth = tokens[6]
	real_ip = tokens[7]

	date = start_time.split(' ')[0]
	st_seconds = get_sec(start_time)
	final_time = get_time_str((duration + st_seconds))

	if (name in logs.keys() and date in logs[name].keys()):
		logs[name][date]['time'].append((start_time, duration, final_time))
		logs[name][date]['info'].append((active, auth, real_ip))
	elif (name in logs.keys()):
		logs[name][date] = { }
		logs[name][date]['time'] = [(start_time, duration, final_time)]
		logs[name][date]['info'] = [(active, auth, real_ip)]
	else:
		logs[name] = {}
		logs[name][date] = {}
		logs[name][date]['time'] = [(start_time, duration, final_time)]
		logs[name][date]['info'] = [(active, auth, real_ip)]

def print_unique_names():
	unique = {}
	for at in invalid_attempt:
		if (at[1] in unique.keys()):
			continue

		unique[at[1]] = 1

	for name in unique.keys():
		print(name)

def print_log_for_name(name):
	logs = []
	invalid = []

	for at in invalid_attempt:
		if (name == at[1]):
			invalid.append(at)

	for at in valid_attempt:
		if (name == at[1]):
			logs.append(at)

	print("##### INVALID ATTEMPTS #####\n")
	for i in invalid:
		print(i)

	print("\n##### VALID LOGINS #####\n")
	for i in logs:
		print(i)

def print_invalid_attempts(name = ''):
	if (name == ''):
		for i in invalid_attempt:
			print(i)

	else:
		for i in invalid_attempt:
			if (name == i[1]):
				print(i)

for name in logs.keys():
	for item in logs[name]:
		if (len(logs[name][item]['time']) > 1):
			time_1_seconds = get_sec(logs[name][item]['time'][0][0])
			total_time_1 = time_1_seconds + logs[name][item]['time'][0][1]
			time_2_seconds = get_sec(logs[name][item]['time'][1][0])

			if (time_2_seconds < total_time_1):
				print('\n==== SUSPICIOUS ====')
				print(name)
				print('\t' + item)
				print(logs[name][item]['time'])
```

In the end, there was a single output that matched the previously explained criteria.

```
==== SUSPICIOUS ====
Bret.P
	2022.01.24
[('2022.01.24 07:56:00 EDT', 18579, '13:05:39'), ('2022.01.24 08:41:17 EDT', 39262, '19:35:39')]
```

The user Bret.P is shown logging in at 7:56 AM EDT and this same session not logging out until 1:05 PM EDT. However, there is another sign in from the same user at 8:41 AM EDT, not long after the first login occurred. This session didn't log out until 7:35 PM EDT. 

Like I said before, even though this isn't necessarily a nail in the coffin - given our circumstance this is a fairly suspicious event to happen, and so we will flag the user for further research.

The correct answer:

`Bret.P`

![Task A1 Badge](/posts/badgea1.png "Task A1 Badge")

- - -