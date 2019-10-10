                                                                     


 ```
                                                                         
  ______   ______   ______   ______   ______   ______   ______   ______   
 /_____/  /_____/  /_____/  /_____/  /_____/  /_____/  /_____/  /_____/   
 /_____/  /_____/  /_____/  /_____/  /_____/  /_____/  /_____/  /_____/   
                                                                          
                                                                          
               .__                         __    __                 __    
_______   ____ |  | _____  ___.__. _____ _/  |__/  |______    ____ |  | __
\_  __ \_/ __ \|  | \__  \<   |  | \__  \\   __\   __\__  \ _/ ___\|  |/ /
 |  | \/\  ___/|  |__/ __ \\___  |  / __ \|  |  |  |  / __ \\  \___|    < 
 |__|    \___  >____(____  / ____| (____  /__|  |__| (____  /\___  >__|_ \
             \/          \/\/           \/                \/     \/     \/
                                                                          
  ______   ______   ______   ______   ______   ______   ______   ______   
 /_____/  /_____/  /_____/  /_____/  /_____/  /_____/  /_____/  /_____/   
 /____/  /_____/  /_____/  /_____/  /_____/  /_____/  /_____/  /_____/   
                                                                          
 ```
                                                                         

                                                 

# Relay Attack

You BTC Relay is broken! 

Fix the bugs and defend yourself against incoming attacks!


May the best team survive....

(HINT: you have to add the correct 'require' statements!)

## Interested? Read up on cross-chain communication our paper: https://eprint.iacr.org/2019/1128.pdf


## Instructions

### Quick

Execute the install shell script with:

```
./install
```

Start the game with:

```
./play
```

### Long

Install `ganache-cli` and `truffle` globally using:

```
npm install -g ganache-cli truffle
```

Install local npm packages from this folder with:

```
npm install
```

Install the Python requirements with:

```
pip3 install --user -r requirements.txt
```

Open a new terminal and start a local ganache-cli server to test your solutions:

```
ganache-cli
```

Start the game in a different terminal window with:

```
python3 play.py
```

## Register

The game will ask you to register a team name. You can re-use your team name and the server will return you your previous team id.

Our script will update your local config file - so, you **only need to register once** and you are good to go!

### Teams
If you work in a team, you have the following options:
+ Use the **same team name** when registering on multiple machines

OR 

+ Use the **same machine** and do pair-programming

## Commands

The game has three commands:

- `test`: runs tests locally on your machine. Use this to test you solutions locally, before submitting.
- `submit`:  Submits your solution to our game server
- `help`:  Local help (just info on commands)
- `hint`: Ask for a HINT for a specific testcase. **NOTE: you will only get 50% of the points for this testcase after this!**
- `quit`: Surrender...
