# bba.chrony

A Chrony NTP server running in Docker Compose on Alpine Linux.

The project keeps configuration in Git and stores runtime state and logs separately on the Docker host.

## Features

- Synchronizes the Linux host clock with upstream NTP sources.
- Serves NTP to permitted LAN clients over UDP port 123.
- Uses Docker host networking.
- Mounts the Git-managed Chrony configuration read-only.
- Persists Chrony drift data and logs under `/opt/chrony`.
- Uses Docker Compose for deployment and updates.

## Requirements

- Linux host
- Docker Engine and Docker Compose plugin
- UDP port 123 available on the host
- A LAN subnet configured in `chrony.conf`

## Repository layout

```text
bba.chrony/
├── compose.yml
├── Dockerfile
├── chrony.conf
├── .dockerignore
├── .gitignore
└── README.md

/opt/chrony/
├── data/
└── logs/
```

Runtime data and logs are not stored in the Git repository.

## Configuration

Edit `chrony.conf` and change the permitted LAN subnet to match your network:

```conf
allow 192.168.X.X/24
```

Keep `allow 127.0.0.1` if local loopback clients need access.

Upstream time sources use the public NTP pool:

```conf
pool pool.ntp.org iburst
```

## Deploy

From the repository directory:

```bash
sudo mkdir -p /opt/chrony/data /opt/chrony/logs
docker compose up -d --build
```

Check the container:

```bash
docker compose ps
docker compose logs -f chrony
```

## Log permissions

Chrony may drop privileges to its `chrony` user when writing logs. If you see `Permission denied`, check the UID and GID:

```bash
docker exec chrony id chrony
```

Use the numeric UID and GID shown by that command to set ownership. For example, if they are `100:101`:

```bash
sudo chown -R 100:101 /opt/chrony/logs
sudo chmod 755 /opt/chrony/logs
docker restart chrony
```

## Verify Chrony

Show upstream sources:

```bash
docker exec chrony chronyc sources -v
```

Show synchronization status:

```bash
docker exec chrony chronyc tracking
```

Show clients:

```bash
docker exec chrony chronyc clients
```

Show server statistics:

```bash
docker exec chrony chronyc serverstats
```

Inspect incoming NTP requests on the host:

```bash
sudo tcpdump -ni any 'udp dst port 123'
```

## Host clock synchronization

The Compose configuration grants `SYS_TIME` to Chrony. This allows Chrony to adjust the Linux host system clock directly.

Do not run another time synchronization service that independently disciplines the same host clock. Use one service to control host clock synchronization.

## Security

- `network_mode: host` exposes the NTP listener directly on the host network.
- Restrict UDP port 123 with your host firewall to trusted networks.
- Do not expose this NTP server to the public internet unless you have a specific, secured reason.
- `SYS_TIME` allows the container to change the host system clock.
- The Chrony `allow` directives are not a replacement for firewall rules.
- Review the LAN subnet in `chrony.conf` before deployment.

## Update

After changing the configuration or Dockerfile:

```bash
docker compose up -d --build
```

## License

No license is included. Add a license if you want to grant others permission to reuse, modify, or distribute this project.
