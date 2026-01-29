# docker-hytale-server
Docker image for creating a Hytale server. I took some ideas from [`indifferentbroccoli/hytale-server-docker`](https://github.com/indifferentbroccoli/hytale-server-docker) 
and [`itzg/docker-minecraft-server`](https://github.com/itzg/docker-minecraft-server/tree/master) (albeit a lot more simpler). This image allows you to do the following through
environment variables, compose.yml, and scripts:
- Modify the `config.json` for the server and each world
- Specify JVM arguments and server options
- Automatically update the server and set downloader flags
- Copy universe files (including worlds) and mods into the server area and overwrite existing ones
- Generate OAuth tokens for authentication externally

Make sure to check Hytale's own pages[[1]](https://support.hytale.com/hc/en-us/articles/45326769420827-Hytale-Server-Manual)[[2]](https://support.hytale.com/hc/en-us/articles/45328341414043-Server-Provider-Authentication-Guide)
for more info on maintaining/configuring the server.

> **Note:** Keep in mind that the Hytale server uses **Java 25** and only supports **x64 and arm64 architectures** currently. You will also need to own the game for authentication.

## Network Configuration
By default the Hytale server uses **UDP port 5520** via the **QUIC protocol**, though this port can be changed with the `ADDRESS` environment variable and in `compose.yml`.
Set your router to forward the port to your server machine if necessary.

### Firewall Rules
Below are some commands to open port 5520 in the firewall of the respective OS.

**Windows Defense Firewall**

```New-NetFirewallRule -DisplayName "Hytale Server" -Direction Inbound -Protocol UDP -LocalPort 5520 -Action Allow```

**Linux (iptables)**

```sudo iptables -A INPUT -p udp --dport 5520 -j ACCEPT```

**Linux (ufw)**

```sudo ufw allow 5520/udp```

## Updating and Downloading Server Files
Updating is done automatically on boot if the `UPDATE_SERVER` variable is set to `true`. Available updates are checked by using the `--print-version` and `--version` flags with the downloader
to determine if there is a newer game and downloader version respectively. On a first time set up you will need to verify online to download the server files.

There are additional variables for controlling the downloader. `FORCE_DOWNLOAD` can be used to forcefully download server files and assets regardless of version. `USE_PRERELEASE` will download
the server from the pre-release channel if `true`, and `SKIP_UPDATE_CHECK` will skip updating the *downloader* if `true`.

## Authentication
### Method 1: Console Authentication
This is the most common way for authenticating servers. If `SESSION_TOKEN` or `IDENTITY_TOKEN` are empty (and if there is no auth.enc file in the container already),
this method will be assumed by default and the server will run **/auth login device** and **/auth persistence Encrypted** immediately on boot.

For a first time setup you will be asked to verify online. After doing so, the server will store and encrypt your credentials in
**auth.enc** so you don't have to verify online for future boots.

### Method 2: Generating Tokens Manually
Running **request_tokens.sh** will automatically fetch the tokens and owner info for you and write them onto a file. 
For example, to place the tokens and owner info into .env, you would run

```./request_tokens.sh .env```

If running for the first time you will be prompted to verify online. The script will then store the refresh token in **.refresh_token** and re-use it for future calls so you 
no longer have to verify each time (up until the refresh token expires at least).

You will have to run this each time before starting the server. **Useful for testing**.

## Optional universe, worlds, and mods attach points
There are optional attach points for universe, worlds, and mod files to be copied into the server area. These attach points are specified by `UNIVERSE_SRC`,
`WORLDS_SRC`, and `MODS_SRC`.

Below is an example of `compose.yml` modified to attach files to the points specified by the variables. In this case they are default values.
```yml
...
    volumes:
      - ./data:/data
      - ./universe:/universe
      - ./mods:/mods
...
```

* `UNIVERSE_SRC`:

Only player data, memories, and warps will be copied (without replacement) from this directory over to the server area. Any player data must be stored in `${UNIVERSE_SRC}/players`.
There are variables `OVERWRITE_PLAYERS`, `OVERWRITE_MEMORIES`, and `OVERWRITE_WARPS` you can set to forcefully replace the existing files in the server area if they already exist.

* `WORLDS_SRC`:

Every world in here will be copied (without replacement) to the server area. If the world already exists, it will be skipped, otherwise you can specify the names of the worlds
you wish to forcefully replace in `OVERWRITE_WORLDS`. 

To modify some of `config.json` of an existing world, you may provide a file **\<world\>.env** in this directory. For example, to edit the config of world `default`, you could provide the following:
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
A full list of all available environment variables is provided below. A simple .env file is included in the repo, but a more complicated .env and \<world\>.env
can be found in [examples/](https://github.com/dylanwilks/docker-hytale-server/tree/main/examples).

| Parameter | Default | Function |
| --- | --- | --- |
| `UID` | `1000` | Run the server as this UID |
| `GID` | `1000` | Run the server as this GID |
| `SESSION_TOKEN` | `""` | Use this session token to authenticate the server |
| `IDENTITY_TOKEN ` | `""` | Use this identity token to authenticate the server |
| `OWNER_UUID` | `""` | Set `--owner-uuid` option for the server |
| `OWNER_NAME` | `""` | Set `--owner-name` option for the server |
| `UPDATE_SERVER` | `true` | Update the server on boot if a new version is found |
| `FORCE_DOWNLOAD` | `false` | Force download server files on boot regardless of version |
| `SKIP_UPDATE_CHECK` | `false` | Skip checking for *downloader* updates |
| `USE_PRELEASE` | `false` | Download server files from the pre-release channel |
| `UPDATE_AOT` | `true` | Train the AOT cache on server update rather than rely on the provided one |
| `VERSION` | `3` | Do not modify |
| `SERVER_NAME` | `"Hytale Server"` | Name of the server |
| `MOTD` | `""` | MOTD of the server |
| `PASSWORD` | `""` | Password required to join the server |
| `MAX_PLAYERS` | `100` | Max number of players allowed in the server |
| `MAX_VIEW_RADIUS` | `32` | Max view radius allowed for players |
| `DEFAULT_WORLD` | `default` | Set the specified world as the default world |
| `DEFAULT_GAMEMODE` | `Adventure` | Set the specified gamemode as the default gamemode |
| `UNIVERSE_SRC` | `/universe` | Directory to copy memories, players, and warps from |
| `WORLDS_SRC` | `/universe/worlds` | Directory to copy worlds from |
| `OVERWRITE_PLAYERS` | `false` | Overwrite the existing players folder |
| `OVERWRITE_MEMORIES` | `false` | Overwrite the existing memories |
| `OVERWRITE_WARPS` | `false` | Overwrite the existing warps |
| `OVERWRITE_WORLDS` | `""` | Overwrite the existing worlds |
| `MODS_SRC` | `/mods` | Directory to copy mods from |
| `REMOVE_OLD_MODS` | `false` | Remove all existing mods |
| `ADDRESS` | `0.0.0.0:5520` | Binds the server to the specified address |
| `ALLOW_OP` | `false` | Allows giving OP to players |
| `ENABLE_BACKUPS` | `true` | Enables automatic backups |
| `BACKUP_FREQUENCY` | `30` | Minutes until backup |
| `BACKUP_MAX_COUNT` | `5` | Max number of backups allowed before pruning |
| `BOOT_COMMAND` | `""` | Commands to run on server start via `--boot-command` |
| `AUTH_MODE` | `authenticated` | Start the server with the specified authentication mode |
| `DISABLE_SENTRY` | `false` | Disables sentry service |
| `ACCEPT_EARLY_PLUGINS` | `false` | Allow for early plugins |
| `VALIDATE_ASSETS` | `false` | Validate assets on server startup |
| `VALIDATE_WORLD_GEN` | `false` | Validate world gen on server startup |
| `VALIDATE_PREFABS` | `""` | Validate prefabs on server startup |
| `JVM_ARGS` | `""` | Set JVM args for the server |

I recommend including **-XX:AOTCache=Server/HytaleServer.aot** under `JVM_ARGS` to make use of the Ahead-Of-Time Cache Hytale provides to speed up boot times. 
If you wish to change the amount of memory the server uses, include **-Xmx8G** and **-Xms8G** for example to set the sizes of the maximum and initial allocation
pools respectively to 8 gigabytes.


## Controlling the Server
I recommend using a terminal multiplexer or similar for any of these.

### Starting the server
Once you've edited the environment variables or optionally generated OAuth tokens as desired, you can run the server using

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

```bash
docker logs hytale-server | less
#or
docker-compose logs | less
```

### Stopping the server
You can simply `CTRL-C` on the server's terminal. Alternatively, run
```
docker-compose down
```
