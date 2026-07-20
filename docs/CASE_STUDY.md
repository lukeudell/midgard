# Midgard: case study source

The narrative for lukeudell.com, rewritten from `source-pages/*.astro`. Where the
original pages implied that code lives in this repository, this corrects rather than
repeats. See `../PROJECT_NOTES.md` §1.

This file is the source for `project.yaml`. Edit here, then mirror into the config.

**Everything in this document is sanitised.** No IP addresses, subnet ranges,
hostnames, VLAN numbers or exploitable model numbers appear, and none may be added.
Zone names are published; the numbers behind them are not. Roles are published;
addresses are not. That omission is deliberate and is itself part of the design. This
is an architecture showcase, not a penetration test invitation.

---

## Overview

A residential network built and operated the way production infrastructure is
operated: segmented, documented, and constructed so that someone else could pick it up
and run it from the written material alone.

Nine VLANs enforce boundaries between seven trust zones. The default rule between
zones is deny. Recursive DNS resolution stays entirely on the premises, so no
third-party resolver ever sees a query. Surveillance footage never touches the
internet. Every firewall exception is explicit and written down with the reason it
exists.

Zero cloud dependencies. Nothing on this network requires a vendor account, a hosted
control plane or an internet connection to keep working.

**Why it belongs in a data engineering portfolio.** The other projects demonstrate
pipelines. This one demonstrates that the same habits apply when nobody is paying for
them: layered architecture, explicit access control, version-controlled documentation,
and a design philosophy that optimises for whoever maintains the thing next. The
network also runs a real telemetry pipeline, described below, though that code is
private and is not part of this repository.

## Design philosophy

> Everything denied by default. Anything allowed is explicit, documented, and
> intentional.

Six principles follow from it:

| Principle | What it means in practice |
|---|---|
| Defence in depth | Multiple overlapping controls, so no single failure is total |
| Least privilege | Minimum required access. Trust is verified, never assumed |
| Segmentation first | Boundaries enforced at L2/L3. The application layer supplements, it does not substitute |
| Local-first | Critical services run without internet. Cloud dependencies are explicitly documented, and there are none |
| Docs as infrastructure | Every configuration decision is written down. Changes are tracked and reversible |
| Family-safe | Content filtering at the DNS layer, so non-technical users get safety without configuring anything |

## Architecture

The physical path from the internet inward, with each hop chosen rather than
inherited.

The ISP's cable modem runs in bridge mode. From there a single gateway handles
routing, firewalling, VLAN isolation and network control. It feeds a managed PoE
switch that trunks VLANs and powers the access points and cameras. Off the switch:
wireless access points mapping SSIDs to VLANs, an always-on infrastructure node, an
on-demand compute server, and an air-gapped video recorder with its cameras.

Wired clients are assigned a VLAN by switch port. Wireless clients are assigned one by
which SSID they join. The infrastructure node serves DNS to every VLAN and wakes the
compute server on demand.

| Component | Role | Criticality |
|---|---|---|
| Gateway | Routing, firewall, VLAN isolation, network control | Critical |
| Core switch | VLAN trunking, PoE for access points and cameras | Critical |
| Infrastructure node | Filtering and recursive DNS, VPN, telemetry ETL, Wake-on-LAN | Critical |
| Wireless APs | SSID-to-VLAN mapping | High |
| Compute server | Media services and lab workloads, powered on demand | Medium |
| Video recorder | Local camera recording, air-gapped from the internet | Medium |

## Four decisions worth writing up

Each of these cost something. The cost is stated, because a decision with no downside
was not a decision.

**Bridge-mode modem.** The ISP's modem does no routing. It hands the connection
straight to the gateway, which means no double NAT and no ISP-controlled routing layer
sitting above the firewall rules. Every routing and filtering decision on the network
is made by equipment that is under local control and locally documented. The cost is
that the gateway is now the only thing standing between the network and the internet,
with no accidental second layer to fall back on.

**On-demand compute via Wake-on-LAN.** The compute server draws significant power at
idle, and the media services it hosts are used episodically rather than continuously.
Rather than running it around the clock, the infrastructure node manages its power
lifecycle: on a schedule, from a touchscreen, by API webhook, or remotely over the
VPN. The server matches the usage pattern instead of the other way round. The cost is
latency on first use and a dependency on the infrastructure node being up to start it.

**Air-gapped surveillance.** The cameras and the recorder have no internet access at
all. Not filtered, not restricted. None. Footage stays on the premises. Remote viewing
works by connecting to the VPN and then viewing locally, never through a vendor's
cloud relay. The cost is convenience: there is no app that just works from anywhere,
and every remote viewer has to hold a VPN configuration. That is the trade being made
deliberately, because a camera network that phones out is a camera network whose
footage is somebody else's problem to secure.

**A single infrastructure node.** DNS filtering, recursive resolution, VPN, telemetry
ETL and power management all run on one always-on device. This is an accepted single
point of failure, chosen for minimal power draw and operational simplicity in a home
setting. The blast radius was reasoned about before it was accepted: if that node
dies, the gateway keeps routing and the network keeps working. What is lost is DNS
filtering and VPN access: degraded, not down. That distinction is the reason the
trade-off is acceptable here and would not be in a data centre.

## Segmentation: nine VLANs, seven trust zones

The short argument for segmenting a home network is that a flat network is a
single-exploit environment. One compromised smart bulb on a flat network can observe
traffic from a work laptop, a child's tablet and a security camera. Each VLAN is a
trust boundary: devices inside one share a trust level, and devices in different zones
cannot talk unless a firewall rule explicitly permits it.

Zones are named after Rod Serling's *The Twilight Zone*. This is a memory aid as much
as a joke. "Is this device in The Machine Realm or Junior Dimension?" is a question
someone can answer correctly from the device's purpose, in a way that "is this on the
first VLAN or the third?" is not. Naming that encodes meaning survives contact with
the person maintaining it six months later.

| Zone | Purpose | Trust | Internet |
|---|---|---|---|
| The Fifth Dimension | Network infrastructure, management plane | Highest | Yes |
| Beyond the Pale | Trusted personal devices, admin access | High | Yes |
| Sector 51 | Employer-managed work devices | Isolated | Yes |
| Junior Dimension | Children's devices, content-filtered | Restricted | Filtered |
| The Viewing Chamber | Televisions and streaming devices | Low | Yes |
| The Loading Dock | Media ingest, download quarantine | Low | Yes |
| The Machine Realm | IoT and smart home devices | Very low | Limited |
| The Outer Limits | Guest devices | Lowest | Yes |
| The Surveillance Sector | Cameras and video recorder | Special | **Blocked** |

### Inter-zone access

The default rule is DENY ALL. Every path that exists is an exception with a written
reason.

**Allowed**

- Infrastructure to every zone, for management
- Trusted to infrastructure, for administration
- Trusted to surveillance, for camera viewing
- Media zones to media services
- Every zone to the DNS server
- VPN clients into the trusted zone

**Blocked**

- IoT to any internal zone
- Guests to any internal resource
- Surveillance to the internet, in either direction
- Work devices to personal devices
- Children's devices bypassing the content filter
- Lateral movement between low-trust zones

Two of these are worth drawing out. Work devices are isolated from personal devices
because the work zone contains employer-managed endpoints running employer-controlled
software; the isolation protects the household from the employer's agent as much as
the reverse. And the surveillance block is bidirectional by design: the zone that
holds the most sensitive data on the network is the one with no route out of it.

## DNS sovereignty

Every DNS query on the network passes through two layers before anything leaves the
premises.

The first is Pi-hole, which filters: advertising, trackers, malware domains and
age-inappropriate content are refused before they resolve, with a stricter list
applied to the children's zone. Queries that pass the filter go to Unbound, a
recursive resolver that walks the DNS hierarchy from the root and talks to
authoritative nameservers directly.

The consequence is the point: **no third-party resolver ever sees a query from this
network.** Not Google, not Cloudflare, not the ISP. There is no forwarder to a public
resolver because there is no forwarding at all. DNSSEC validation is enforced on the
results.

The enforcement matters as much as the mechanism. Devices increasingly ship with their
own DNS-over-HTTPS or DNS-over-TLS resolvers configured by the vendor, which would
route around all of the above silently. Those paths, and direct queries to external
resolvers, are blocked at the firewall. A device on this network resolves through
Pi-hole or it does not resolve. This is the difference between a filter and a control:
a filter is what a device uses when it chooses to, a control is what it uses because
there is no alternative.

## Remote access

WireGuard, using ChaCha20 and Curve25519, provides VLAN-aware remote access. Clients
are routed into the trusted zone, which gives them infrastructure, media and
surveillance access, the last being the only way to view cameras from outside the
house, since the cameras themselves have no route to the internet.

VPN client DNS is forced through Pi-hole, so a remote client gets the same filtering
and the same privacy properties as a device sitting in the house. Remote access does
not mean degraded policy.

## Network telemetry

The network runs a Python ETL on a systemd timer, every fifteen minutes. It pulls
device state, client connections, traffic statistics and network events from the
controller's API and loads them into a local PostgreSQL instance.

> **This code is private.** It runs on the infrastructure node and is documented in a
> private vault, not in this repository. What follows describes its design, not code
> you can read here.

The stored history is what makes it more than a status page. Four things it enables:

- **Alerting.** Email notification on devices going offline and on new clients
  appearing on the network.
- **Historical analysis.** Traffic trends, device uptime history, daily aggregates.
- **Anomaly detection.** Unexpected devices, unusual traffic patterns, firmware drift.
- **Audit trail.** Which client connected, when, to which zone, and how much bandwidth
  it used.

The pattern is the same one used professionally: scheduled extraction from an API,
loaded into a relational store, with a history worth querying rather than a dashboard
worth glancing at. The distinction between monitoring and telemetry is whether you can
ask questions about last month.

A ten-inch touchscreen on the infrastructure node surfaces the live picture: DNS query
statistics, active VPN connections, VLAN utilisation, and the power control for the
compute server.

## Documentation as artifact

The network documentation is a deliverable, not an afterthought. Its README is itself
a structured reference with a table of contents, a navigation guide and a version
history. Behind it are fifteen or more pages across four numbered sections.

```
01-Configuration/    How each component is set up, written so it can be rebuilt
02-Reference/        Naming conventions, password standards, port reference
03-Operations/       Runbooks. The largest section, by design
04-Scripts/          Automation, each script documented with when and why to run it
Missing-Info.md      A living backlog of documentation gaps
```

Four practices keep it from rotting:

**Version control with a changelog.** The documentation lives in Git and the README
carries a changelog. Architecture changes trigger a version bump; the current version
is 5.1, reflecting a migration from a previous gateway platform.

**A documentation debt backlog.** `Missing-Info.md` tracks what still needs writing.
The docs are never finished, in the same way the network is never finished, and
pretending otherwise is how documentation quietly becomes fiction.

**Naming conventions as a document.** One page defines the scheme for every device,
zone and service. New components are named by the convention rather than by whatever
seemed clever that evening. Consistency over creativity.

**A review cadence.** Quarterly, or after any major architecture change, whichever
comes first. This exists to prevent the standard failure mode: documentation that is
accurate on day one and wrong by month three.

Operations is the largest section on purpose. The documents that earn their keep are
the ones consulted at two in the morning when something has broken and nobody
remembers the correct command sequence.

### The same pattern, different domain

The structure is not an analogy to professional practice. It is the same practice.

| Home network | Equivalent at work |
|---|---|
| 01-Configuration | Infrastructure-as-code, environment setup guides |
| 02-Reference | ADRs, coding standards, schema documentation |
| 03-Operations | Runbooks, incident response playbooks, on-call guides |
| 04-Scripts | CI/CD pipelines, migration scripts, automation |
| Missing-Info.md | Documentation debt backlog |

> The tools change. The pattern doesn't.
