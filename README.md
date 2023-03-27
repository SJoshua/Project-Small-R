# Project-Small-R
A Telegram Bot Framework in Lua.

## Requirement
* Operating System: UNIX
* Lua 5.1+

## Dependence
* Lua-socket
* Lua-cjson
* Lua-ssl
* Lua-ltn12
* Lua-multipart-post

## Bots
* [@small_robot](https://t.me/small_robot): A chat bot with some interesting features in English, Chinese and Japanese.

## Deployment
I am using luaver as Lua Version Manager. This is an example with debian/ubuntu.

1. Install dependencies of luaver. `sudo apt-get install libreadline-dev`
2. Install luaver. `curl -fsSL https://raw.githubusercontent.com/dhavalkapil/luaver/master/install.sh | sh -s - -r v1.1.0`
3. Restart your shell.
4. Install Lua 5.3.5. `luaver install 5.3.5`
5. Install Luarocks 3.9.2. `luaver install-luarocks 3.9.2`
6. Switch to Lua 5.3.5 and Luarocks 3.9.2. `luaver use 5.3.5 && luaver use-luarocks 3.9.2`
7. Install dependency of luasec. `sudo apt install libssl-dev`
8. Install dependencies of this project. `cat requirements.txt | xargs -L 1 luarocks install --local`
9. Edit `src/config.lua` (copy from `src/config-example.lua`).
10. Start bot. `cd src && lua bot.lua`