# PostgreSQL & Patroni High-Availability Architecture Guide

In a Patroni-managed high-availability PostgreSQL cluster, Patroni acts as a control plane agent running alongside PostgreSQL on every node. It uses a Distributed Configuration Store (**Consul**) to achieve automatic consensus, leader election, and health tracking.

---

## 1. Which IP does your application have to use?

Your application **should never hardcode a specific node's IP or container port**, because the role of a node can change dynamically (today's primary can become tomorrow's dead replica). Instead, your application connects using **Consul Service Discovery**.

* **For Writes & Reads (Primary):** `postgres-primary.service.consul:5432`
* **For Read-Only Queries (Replicas):** `postgres-replica.service.consul:5432`

### How this works under the hood:
1. In your Nomad job, you defined a Consul health check pointing to Patroni's REST API endpoint (`/primary` or `/replica` on port `8008`).
2. Patroni's API returns `HTTP 200 OK` **only** on the node currently holding the active primary leadership lock in Consul. It returns `HTTP 503` on all standby nodes.
3. Consul's internal health checker monitors these HTTP checks. When Consul sees a node transition to primary, it dynamically updates its internal DNS records. Therefore, querying `postgres-primary.service.consul` always routes your application traffic directly to the active primary node's current IP and dynamic port.

---

## 2. How does the failover scenario work when the primary node goes down?

When the primary node crashes, loses power, or suffers a severe network partition, Patroni and Consul handle the recovery automatically without manual intervention.

```text
[Node 1: Primary (DEAD)] --x-- (TTL Expires) ---> [Consul Releases Lock]
                                                        │
                                                        ▼
                                              [Node 2 or 3 Promoted]
                                                        │
                                                        ▼
[Consul Updates DNS] <-------------------- [Patroni Acquires New Lock]
        │
        ▼
[App Reconnects to new Primary automatically]
```

### No Load balancer solution 

DATABASE_URL=postgres://user:pass@host1:5432,host2:5432,host3:5432/database?sslmode=require&target_session_attrs=primary
