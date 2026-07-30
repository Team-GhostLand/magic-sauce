# magic-sauce
Auxiliary services for GhostLand.

## Docker Services
Docker services are all listed in the `compose.yml` file and are intended to be run via `docker compose` (podman is untested and considered unsupported)

### `web`
The main web server, Caddy. See section below for more.

### `web-custom`
[Our website](https://github.com/Team-GhostLand/GL-web/), made by [Jifo](https://jifo.dev/).

### `bot-account`
A deployment of [Poltergeist](https://github.com/Team-GhostLand/GL-web/), our account system Discord bot. Called „Konto GhostLand” (GhostLand Account) on Discord - not to be confused with the one called Poltergeist, which is the chat relay.

### `jifo-snatcher`
Responisble for snatching up various files that JifoCC spreads around the system without any care for the services consuming them. Originally designed specifically for taking player stats from all the random instances (hence `statd.sh`), is now also responsible for taking the Minecraft server status.

**When running the stack locally for development, you'll want to disable this one** or it'll traverse outside of your workspace. Thankfully, despite some admittedly sketchy things it does (notably - executing scripts provided directly by instance files), it's actually secured decently well (no internet access and (relevantly here) *all out-of-bounds mounts are readonly*), so it cannot mess up your system. Still, it's probably gonna throw a bunch of errors and it'll be a pain to otherwise prevent them (you'd need to create some mock data outside of your workspace, which is a recipe for a file you'll forget exists, and will sit on your system forever).

### `db`
Database.

## Web services
All the paths exposed by the web service. This section effectively serves as the GhostLand API documentation
* `/external/` - Below are all the services that are external to `web-custom`. However, this path itself redirects here, so that you can see the documentation for the very route you tried to open. Smart, eh?
* `/external/[name]` - Reverse-proxy for all the services that may be exposed by other parts of the GhostLand system, eg. things like map mods (Create Track Map / Surveyor) or services that „do a lot of stuff”, eg. `bot-account`. Currently, the valid `[name]`s (ie. the services we expose) that won't throw you a `404`, are: *None.* ~~(yea, we don't have anything rn.... Used to have Poltergeist but not anymore (I shot it down initially because that webserver implementation was completely detached from everything else PG does (Jifo just added a random endpoint that would let him send messages via the webhook - but PG's webhook is used for error logging not announcements, and besides you don't need a full bot to send webhooks, that's their whole point), but after careful consideration, I can see some reasons for that, but I'm not doing it yet.) and CTM, but it's unsupported now.)~~
* `/external/files` - A special endpoint that isn't a reverse proxy, but a mount of `downloads/`. It's there to let you, well, *download* stuff, ie.
* `/external/files/modpacks` - self-explanatory
* `/external/files/screenshots` - same here
* `/external/files/misc` - Various things that „just needed a place to be put somewhere”, eg. old world saves, development modpacks, ultra-legacy modpacks, etc.
* `/external/files/api` - Contains JSON files that can be used to get various data about the server. Yes, our API *is in fact* just static files. So what? If it works, it works.
* `/external/files/api/settings.json` - Data provided to `web-custom`, about things like eg. the countdown display. Refer to [this GL-web file](https://github.com/Team-GhostLand/GL-web/blob/jifo/src/lib/settings.tsx) for the typedef (exported type `Settings`).
* `/external/files/api/status.json` - What instance is running, if any are running. Ping it to see the format (can't put a link to the typedef here because JifoCC is private).
* *Everything unmatched by the previous rules (notably, even `/modules` - it's different than `/external/`, after all) gets sent back to `gl-web`, to let it operate normally.*