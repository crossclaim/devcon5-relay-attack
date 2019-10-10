#!/usr/bin/env python
#coding: utf8
from __future__ import print_function  # Only Python 2.x

import json
import subprocess
import sys
import os
from subprocess import CalledProcessError

import requests

BASE = "http://localhost:3000"
TESTS = {
    "1": False,
    "2": False,
    "3a": False,
    "3b": False,
    "4": False,
    "5": False,
    "6": False,
    "7": False,
    "8": False,
    "9": False
}


def print_file(name):
    with open(os.path.join("docs", name), "r") as file:
        text = file.read()
    print(text)


def read_config():
    try:
        with open("config.json", "r") as file:
            config = json.load(file)
    except FileNotFoundError:
        config = {}

    return config


def update_config(config):
    with open("config.json", "w+") as file:
        json.dump(config, file)


def execute(cmd):
    popen = subprocess.Popen(
        cmd, stdout=subprocess.PIPE, universal_newlines=True)
    for stdout_line in iter(popen.stdout.readline, ""):
        yield stdout_line
    popen.stdout.close()
    return_code = popen.wait()
    if return_code:
        raise subprocess.CalledProcessError(return_code, cmd)


def init():
    os.system('cls' if os.name=='nt' else 'clear')
    print_file("banner.txt")
    print_file("intro.txt")


def user_input(message):
    if sys.version_info[0] < 3:
        my_input = raw_input(message)
    else:
        my_input = input(message)

    return my_input


def register():
    url = BASE + "/api/register"
    name = None

    while not name:
        name = user_input("Please enter your team name: ")
    data = json.dumps({"name": name})

    try:
        request = requests.post(
            url, headers={'Content-Type': 'application/json'}, data=data)
        response = request.json()

    except:
        print("Something went wrong with the server")

    config["name"] = response["name"]
    config["id"] = response["id"]
    config["tests"] = TESTS
    update_config(config)

    print(response["message"])


def hint():
    # return which cases are not yet solved
    print("")
    # ask which case is solved now
    next_test = user_input(
        "Please enter the number of the attack you want to have a hint for: ")

    url = BASE + "/api/hint?id={}&case={}".format(config["id"], next_test)

    open_problems = []
    for key, value in config["tests"].items():
        if not value:
            open_problems.append(key)

    print("You are under attack! Problems {} are not yet solved!".format(open_problems))

    if not next_test in config["tests"]:
        print("Please enter a valid number!")
        return

    # Print which test case is submitted
    # print("You are submitting the solution for case {}".format(next_test))

    # get the testcase from the server
    try:
        # submit team_id
        request = requests.get(url)
        # print(request.status_code)
        # print(request._content)
        response = request.json()

    except:
        print("Problem with getting the test case from the server")

    try:
        with open(os.path.join("test", response["name"]), "w+") as test_file:
            test_file.write(response["content"])
    except:
        print("Hint already fetched from the server")


def submit():
    url = BASE + "/api/submit"

    print("Upgrading defenses...")
    # run tests locally
    results = {}
    try:
        # perform tests locally
        # parses the output line by line
        for output in execute(["truffle", "test"]):
            # check if it includes the testcases
            if "TESTCASE" in output:
                # split the output string into a list
                # list[0] is the result of the test (pass/fail)
                # list[1] is test case number plus any additional information
                output_list = output.split(" TESTCASE ", 1)
                # list[1] looks like "1: set ....". Split at : and return the first elemet
                testcase = output_list[1].split(":", 1)[0]
                # store the result of the testcase
                if "✓" in output_list[0]:
                    results[testcase] = True
                    config["tests"][testcase] = True
                    update_config(config)
                    print("You successfully completed testcase {}.".format(testcase))
                else:
                    results[testcase] = False
                    print("Sorry, testcase {} failed. TIP: you can request a hint and see the testcase in the 'test' folder.".format(
                        testcase))
        print("===== Congratulations! You have completed the game!")
    except CalledProcessError:
        print("===== Oh no, you are still vulnerable! ====")

    # report results to server
    # prepare submission with team id
    data = json.dumps({
        'id': config['id'],
        'results': results
    })

    # submit
    try:
        request = requests.post(
            url, headers={'Content-Type': 'application/json'}, data=data)
        response = request.json()

        print(response["message"])
    except:
        print("Something went wrong with the server")

    score()


def leaders():
    url = BASE + "/api/leaderboard"
    # get the leaderboard
    request = requests.get(url)
    # returns a sorted list of teams
    response = request.json()

    leaderboard = []

    # print(response)

    for team in response['teams']:
        leaderboard.append((team["name"], team["score"]))

    for i in range(len(leaderboard)):
        name = leaderboard[i][0]
        score = leaderboard[i][1]
        print("{:2}: {:30} {:3}".format(i+1, name, score))

    # print(json.dumps(response))


def score():
    url = BASE + "/api/score?id={}".format(config["id"])
    # get your current score and rank
    request = requests.get(url)
    response = request.json()
    team = response["team"]

    print("Your total score is {}.".format(team["score"]))
    print("Detailed score breakdown:")
    for key, value in TESTS.items():
        test = "test{}".format(key)
        hint = "hint{}".format(key)
        score = team[test]
        if team[hint]:
            print("Testcase {:2}: {:2} (hint requested)".format(key, score))
        else:
            print("Testcase {:2}: {:2}".format(key, score))


def test():
    try:
        for output in execute(["truffle", "test"]):
            print(output, end="")
    except CalledProcessError:
        print("===== Tests failed ====")


def display_help():
    print("You have the following options:\n"
          "hint:    Asks you to submit a testcase number and gives you the testcase.\n"
          "         Requesting a hint will reduce the score you can get for that testcase by 50%.\n"
          "test:    Locally executes 'truffle test' to give you feedback on your contract.\n"
          "submit:  Evaluates your contract and you will get a score.\n"
          "score:   See your current score for each testcase.\n"
          "leaders: Displays the leaderboard.\n"
          "help:    Displays this help.\n"
          "quit:    End the game.")


def stop():
    print("Thanks for playing!")
    sys.exit()


config = read_config()

if __name__ == "__main__":
    init()
    register()
    command = None
    while not command:
        print("")
        command = user_input(
            "What would you like to do next?\n(hint/test/submit/score/leaders/help/quit): ")
        print("")
        if command == "help":
            display_help()
        elif command == "hint":
            hint()
        elif command == "score":
            score()
        elif command == "quit":
            stop()
        elif command == "submit":
            submit()
        elif command == "test":
            test()
        elif command == "leaders":
            leaders()
        else:
            print("'{}' not understood. Type 'help' for help and 'quit' to exit.".format(command))
        command = None
