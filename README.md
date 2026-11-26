# bba.chrony

A small, self-managed Chrony NTP server running in Docker Compose on Alpine Linux.

The project keeps configuration under version control and stores runtime state and logs separately on the Docker host.

## Features

- Chrony synchronizes the host system clock with upstream NTP sources.
- Serves NTP to permitted LAN clients over UDP port 123.
- Uses Docker host networking.
- Keeps `chrony.conf` in the Git repository and mounts it read-only.
- Persists Chrony's drift data and logs under `/opt/chrony`.
- Uses Docker Compose for deployment and updates.

## Requirements

- Linux host
- Docker Engine and Docker Compose plugin
- UDP port 123 available on the host
- A LAN subnet configured in `chrony.conf`

## Project layout

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

The repository contains configuration and deployment files only. Do not commit runtime data or logs.

## Configuration

Edit `chrony.conf` and set the permitted client subnet:

```conf
allow 192.168.0.0/24
```

Replace the example subnet with your actual LAN subnet. Keep `allow 127.0.0.1` if local loopback clients need access.

Upstream time sources are configured with:

```conf
pool pool.ntp.org iburst
```

You can replace this with your preferred NTP pool or servers.

## Deploy

Clone the repository and enter its directory. Then create the runtime directories and start the service:

```bash
sudo mkdir -p /opt/chrony/data /opt/chrony/logs
docker compose up -d --build
```

Check the service:

```bash
docker compose ps
docker compose logs -f chrony
```

### Log directory permissions

Chrony may drop privileges to its `chrony` user. If the logs show `Permission denied`, check the UID and GID inside the image:

```bash
docker exec chrony id chrony
```

For example, if the output reports UID `100` and GID `101`, set ownership as follows:

```bash
sudo chown -R 100:101 /opt/chrony/logs
sudo chmod 755 /opt/chrony/logs
docker restart chrony
```

Use the actual UID and GID reported by your container.

## Verify synchronization

Show upstream sources:

```bash
docker exec chrony chronyc sources -v
```

Show synchronization details:

```bash
docker exec chrony chronyc tracking
```

Show clients that have queried Chrony:

```bash
docker exec chrony chronyc clients
```

Show server statistics:

```bash
docker exec chrony chronyc serverstats
```

Inspect incoming NTP packets on the host:

```bash
sudo tcpdump -ni any 'udp dst port 123'
```

## Host clock synchronization

This Compose setup grants `SYS_TIME` to Chrony. Chrony can therefore discipline the Linux host's system clock directly.

Do not configure another time synchronization service, such as `systemd-timesyncd`, to discipline the same host clock at the same time. Use one host clock synchronization service.

If you switch to a design where Chrony does not have permission to adjust the host clock, configure and manage host time synchronization separately.

## Security notes

- `network_mode: host` exposes Chrony's NTP listener directly on the host network.
- Restrict UDP port 123 with your host firewall to trusted networks.
- Do not expose this NTP server to the public internet unless you have a specific, secured reason.
- `SYS_TIME` allows the container to change the host system clock. Grant it only when this is intended.
- The `allow` directives are not a replacement for firewall rules.
- Review the configuration before deploying it on an untrusted network.

## Updating

After changing `chrony.conf` or the Dockerfile, rebuild and recreate the container:

```bash
docker compose up -d --build
```

## License

No license is included. Add a license if you want to grant others permission to reuse, modify, or distribute this project.
