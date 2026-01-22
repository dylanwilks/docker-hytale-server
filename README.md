# docker-hytale-server
Docker image for creating a Hytale server. I took some ideas from [`indifferentbroccoli/hytale-server-docker`](https://github.com/indifferentbroccoli/hytale-server-docker) 
and [`itzg/docker-minecraft-server`](https://github.com/itzg/docker-minecraft-server/tree/master) (albeit a lot more simpler). This image allows you to do the following
through environment variables:
- Modify the `config.json` for the server and each world
- Specify JVM arguments and server options
- Automatically update the server and set downloader flags
- Copy worlds and mods into the container and overwrite existing ones
- Generate OAuth tokens for authentication externally

Make sure to check Hytale's own pages[[1]](https://support.hytale.com/hc/en-us/articles/45326769420827-Hytale-Server-Manual)[[2]](https://support.hytale.com/hc/en-us/articles/45328341414043-Server-Provider-Authentication-Guide)
for more info on maintaining/configuring the server.

> **Note:** Keep in mind that the Hytale server requires Java 25 and only supports x64 and arm64 architectures currently. You will also need to own the game for authentification.

## Network Configuration
By default the Hytale server uses **UDP port 5520** via the **QUIC protocol**, though this port can be changed with the `ADDRESS` environment variable and in `compose.yml`.
Set your router to forward the port to your server machine if necessary.

### Firewall Rules
Below are some commands to open port 5520 on the respective OS.

**Windows Defense Firewall**

```New-NetFirewallRule -DisplayName "Hytale Server" -Direction Inbound -Protocol UDP -LocalPort 5520 -Action Allow```

**Linux (iptables)**

```sudo iptables -A INPUT -p udp --dport 5520 -j ACCEPT```

**Linux (ufw)**

```sudo ufw allow 5520/udp```

## Authentication
### Method 1: Console Authentication
This is the most common way for authentifying servers. If `SESSION_TOKEN` or `IDENTITY_TOKEN` are empty (and if there is no `auth.enc` file in the container already),
this method will be assumed by default and the server will run `/auth login device` and `/auth persistence Encrypted` immediately
on boot.

For a first time setup you will be asked to verify online. After doing so, the server will store and encrypt your credentials in
`auth.enc` so you don't have to verify online for future boots.

### Method 2: Generating Tokens
Running `request_tokens.sh` will automatically fetch the tokens for you and write them onto a file. 
For example, to place the tokens in .env, you would run

```./request_tokens.sh .env```

If running for the first time you will be prompted to verify online. The script will then store the refresh token in `.refresh_token` and re-use it so you don't
have to verify for future calls (up until the refresh token expires at least).

You will have to run this each time before starting the server. **Useful for testing**.

## Optional universe, worlds, and mods attach points
There are optional attach points for universe, worlds, and mod files to be copied into the server area. These attach points are specified by `UNIVERSE_SRC` (DEFAULT: `/universe`),
`WORLDS_SRC` (DEFAULT: `/universe/worlds`), and `MODS_SRC` (DEFAULT: `/mods`).

Below is an example of `compose.yml` modified to attach to these points using the default values.
```yml
...
    volumes:
      - ./data:/data
      - ./universe:/universe
      - ./mods:/mods
...
```

* `UNIVERSE_SRC`:

Only player data, memories, and warps will be copied (without replacement) from this directory to the server area. Any player data must be stored in `${UNIVERSE_SRC}/players`.
There are variables you can set (see *Environment Variables*) to forcefully replace the existing files in the server area if they already exist.

* `WORLDS_SRC`:

Every world in here will be copied (without replacement) to the server area. If the world already exists, it will be skipped, otherwise you can specify the names of the worlds
you wish to forcefully replace in `OVERWRITE_WORLDS`. 

To modify some of `config.json` of an existing world, you may provide a file `<world>.env` in this directory. For example, to edit the config of world `default`, you could provide the following:
```env
#default.env
TICKING=true
BLOCK_TICKING=true
PVP=false
FALL_DAMAGE=true
GAME_TIME_PAUSED=false
SPAWN_NPCS=true
SPAWN_MARKERS=true
FROZEN_NPCS=false
COMPASS_UPDATING=true
SAVING_PLAYERS=true
SAVING_CHUNKS=true
SAVE_NEW_CHUNKS=true
UNLOADING_CHUNKS=true
OBJECTIVE_MARKERS=true
DELETE_ON_REMOVE=false
```

* `MODS_SRC`:

Copies essentially everything in here to the mods folder in the server area (without replacement). This includes config files. Setting `REMOVE_OLD_MODS` to `true`
will remove everything in the server's `mods/` directory on boot.


## Environment Variables

## Controlling the Server
I recommend using a terminal multiplexer or similar for any of these.

### Starting the server
Once you've edited the enviromment variables or optionally generated OAuth tokens as desired, you can run the server using

```docker-compose up```, or
```bash
docker volume create data #if using named volumes
docker run -d \
    --name hytale-server \
    -p 5520:5520/udp \ #assuming port 5520
    --env-file .env \
    -v data:/data \
    -it \
    dylanwilks/docker-hytale-server
```

### Accessing the server terminal
```docker attach hytale-server```

### Viewing logs

```
docker logs hytale-server -f
#or
docker-compose logs -f
```

### Stopping the server
You can simply `CTRL-C` on the server's terminal. Alternatively, run
```
docker-compose down
```
